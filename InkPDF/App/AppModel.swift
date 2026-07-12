//
//  AppModel.swift
//  InkPDF
//
//  Owns the document library (the app's Documents directory), routing to
//  the reader, deep links coming from the widgets, and recents/widget sync.
//

import Foundation
import PDFKit
import SwiftUI
import WidgetKit

/// A PDF file living in the app's Documents directory.
struct DocumentItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let modified: Date
    let sizeBytes: Int

    var id: URL { url }

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}

/// Wrapper so `fullScreenCover(item:)` can present the reader.
struct OpenedDocument: Identifiable {
    let url: URL
    var id: URL { url }
}

@MainActor
final class AppModel: ObservableObject {

    @Published var documents: [DocumentItem] = []
    @Published var openedDocument: OpenedDocument?
    @Published var showImporter = false
    @Published var errorMessage: String?

    let documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    private static let welcomeFlagKey = "io.inkpdf.didCreateWelcome"

    init() {
        createWelcomeDocumentIfNeeded()
        refresh()
    }

    // MARK: - Library

    func refresh() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: documentsDirectory,
                                                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                                                options: [.skipsHiddenFiles])) ?? []
        documents = urls
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .compactMap { url in
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                return DocumentItem(url: url,
                                    name: url.deletingPathExtension().lastPathComponent,
                                    modified: values?.contentModificationDate ?? .distantPast,
                                    sizeBytes: values?.fileSize ?? 0)
            }
            .sorted { $0.modified > $1.modified }
    }

    /// Copy external PDFs (Files app, share sheet, "Open in…") into the library.
    func importPDFs(from urls: [URL], openFirst: Bool = false) {
        var firstImported: URL?
        for url in urls {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            do {
                let destination = uniqueDestination(forProposedName: url.deletingPathExtension().lastPathComponent)
                try FileManager.default.copyItem(at: url, to: destination)
                if firstImported == nil { firstImported = destination }
            } catch {
                errorMessage = "Could not import “\(url.lastPathComponent)”: \(error.localizedDescription)"
            }
        }
        refresh()
        if openFirst, let firstImported {
            open(url: firstImported)
        }
    }

    /// Create a fresh notebook (blank / lined / grid / dotted paper) and open it.
    func createNotebook(name: String, style: PaperStyle, pageSize: NotebookPageSize, pageCount: Int) {
        let data = NotebookFactory.notebookData(style: style, pageSize: pageSize.size, pageCount: pageCount)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let destination = uniqueDestination(forProposedName: cleanName.isEmpty ? "Notebook" : cleanName)
        do {
            try data.write(to: destination, options: .atomic)
            refresh()
            open(url: destination)
        } catch {
            errorMessage = "Could not create the notebook: \(error.localizedDescription)"
        }
    }

    func rename(_ item: DocumentItem, to newName: String) {
        let cleanName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, cleanName != item.name else { return }
        let destination = uniqueDestination(forProposedName: cleanName)
        do {
            try FileManager.default.moveItem(at: item.url, to: destination)
            SharedStore.remove(fileName: item.url.lastPathComponent)
            refresh()
            reloadWidgets()
        } catch {
            errorMessage = "Could not rename the document: \(error.localizedDescription)"
        }
    }

    func duplicate(_ item: DocumentItem) {
        let destination = uniqueDestination(forProposedName: item.name + " copy")
        do {
            try FileManager.default.copyItem(at: item.url, to: destination)
            refresh()
        } catch {
            errorMessage = "Could not duplicate the document: \(error.localizedDescription)"
        }
    }

    func delete(_ item: DocumentItem) {
        do {
            try FileManager.default.removeItem(at: item.url)
            SharedStore.remove(fileName: item.url.lastPathComponent)
            refresh()
            reloadWidgets()
        } catch {
            errorMessage = "Could not delete the document: \(error.localizedDescription)"
        }
    }

    // MARK: - Opening documents

    func open(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "The document “\(url.lastPathComponent)” no longer exists."
            return
        }
        openedDocument = OpenedDocument(url: url)
        updateRecents(for: url)
    }

    func readerDidClose() {
        openedDocument = nil
        refresh()
        reloadWidgets()
    }

    /// Handles both the `inkpdf://` scheme (widgets) and `file://` URLs
    /// ("Open in InkPDF" from the Files app or another app).
    func handle(url: URL) {
        if url.isFileURL {
            importPDFs(from: [url], openFirst: true)
            return
        }
        guard url.scheme?.lowercased() == SharedStore.urlScheme else { return }
        switch url.host?.lowercased() {
        case "open":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let fileName = components?.queryItems?.first(where: { $0.name == "file" })?.value else { return }
            let target = documentsDirectory.appendingPathComponent(fileName)
            openedDocument = nil // dismiss any currently open reader first
            DispatchQueue.main.async { [weak self] in
                self?.open(url: target)
            }
        case "import":
            openedDocument = nil
            showImporter = true
        default:
            break
        }
    }

    // MARK: - Recents + widgets

    /// Refresh the shared recents entry (and its widget thumbnail) for a
    /// document. When `pageIndex` is nil the stored reading position is kept.
    func updateRecents(for url: URL, pageIndex: Int? = nil) {
        let fileName = url.lastPathComponent
        let displayName = url.deletingPathExtension().lastPathComponent
        Task.detached(priority: .utility) {
            guard let document = PDFDocument(url: url) else { return }
            let stored = SharedStore.loadRecents().first(where: { $0.fileName == fileName })
            let pageIndex = pageIndex ?? stored?.pageIndex ?? 0
            let pageCount = document.pageCount
            var thumbnail: UIImage?
            if let page = document.page(at: min(max(pageIndex, 0), max(pageCount - 1, 0))) {
                let bounds = page.bounds(for: .cropBox)
                let scale = 360 / max(bounds.width, 1)
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                thumbnail = page.thumbnail(of: size, for: .cropBox)
            }
            SharedStore.touch(fileName: fileName,
                              displayName: displayName,
                              pageIndex: pageIndex,
                              pageCount: pageCount,
                              thumbnail: thumbnail)
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Helpers

    private func uniqueDestination(forProposedName name: String) -> URL {
        let fm = FileManager.default
        var candidate = documentsDirectory.appendingPathComponent(name).appendingPathExtension("pdf")
        var counter = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = documentsDirectory.appendingPathComponent("\(name) \(counter)").appendingPathExtension("pdf")
            counter += 1
        }
        return candidate
    }

    private func createWelcomeDocumentIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.welcomeFlagKey) else { return }
        let destination = documentsDirectory.appendingPathComponent("Welcome to InkPDF.pdf")
        if !FileManager.default.fileExists(atPath: destination.path) {
            try? NotebookFactory.welcomeData().write(to: destination, options: .atomic)
        }
        defaults.set(true, forKey: Self.welcomeFlagKey)
    }
}
