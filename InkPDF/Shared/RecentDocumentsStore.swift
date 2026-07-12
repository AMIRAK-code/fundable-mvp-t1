//
//  RecentDocumentsStore.swift
//  InkPDF
//
//  Shared between the app and the widget extension via an App Group.
//  If the App Group is not configured (e.g. right after cloning, before
//  you pick your own group identifier), everything degrades gracefully:
//  the app works normally and the widget shows an empty state.
//

import Foundation
import UIKit

/// One entry in the "recently opened documents" list shown by the widgets.
struct RecentDocument: Codable, Identifiable, Hashable {
    /// The file name inside the app's Documents directory (acts as the stable id).
    var fileName: String
    var displayName: String
    var lastOpened: Date
    var pageIndex: Int
    var pageCount: Int
    var thumbnailFileName: String?

    var id: String { fileName }

    /// Deep link that opens this document in the app (handled in `AppModel.handle(url:)`).
    var openURL: URL {
        var components = URLComponents()
        components.scheme = SharedStore.urlScheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "file", value: fileName)]
        return components.url ?? URL(string: "\(SharedStore.urlScheme)://open")!
    }

    var progressText: String {
        guard pageCount > 0 else { return "" }
        return "Page \(pageIndex + 1) of \(pageCount)"
    }
}

/// App Group backed storage for the recents list + widget thumbnails.
enum SharedStore {

    /// ⚠️ Change this to your own App Group identifier (and update both
    /// .entitlements files) after cloning. See README.md → "Getting started".
    static let appGroupID = "group.com.inkpdf.shared"

    /// Custom URL scheme registered in the app's Info.plist.
    static let urlScheme = "inkpdf"

    static let recentsKey = "recents.v1"
    static let maxRecents = 8

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var thumbnailsDirectory: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Recents

    static func loadRecents() -> [RecentDocument] {
        guard let data = defaults?.data(forKey: recentsKey) else { return [] }
        return (try? JSONDecoder().decode([RecentDocument].self, from: data)) ?? []
    }

    static func saveRecents(_ recents: [RecentDocument]) {
        guard let defaults else { return }
        if let data = try? JSONEncoder().encode(recents) {
            defaults.set(data, forKey: recentsKey)
        }
    }

    /// Insert/update an entry at the front of the recents list and
    /// (optionally) refresh its widget thumbnail.
    static func touch(fileName: String,
                      displayName: String,
                      pageIndex: Int,
                      pageCount: Int,
                      thumbnail: UIImage?) {
        var recents = loadRecents().filter { $0.fileName != fileName }

        var thumbnailFileName: String?
        if let thumbnail, let dir = thumbnailsDirectory {
            let name = sanitizedThumbnailName(for: fileName)
            if let data = thumbnail.pngData() {
                try? data.write(to: dir.appendingPathComponent(name), options: .atomic)
                thumbnailFileName = name
            }
        } else {
            // Keep a previously written thumbnail if we did not get a new one.
            thumbnailFileName = loadRecents().first(where: { $0.fileName == fileName })?.thumbnailFileName
        }

        let entry = RecentDocument(fileName: fileName,
                                   displayName: displayName,
                                   lastOpened: Date(),
                                   pageIndex: pageIndex,
                                   pageCount: pageCount,
                                   thumbnailFileName: thumbnailFileName)
        recents.insert(entry, at: 0)
        if recents.count > maxRecents {
            recents = Array(recents.prefix(maxRecents))
        }
        saveRecents(recents)
    }

    static func remove(fileName: String) {
        let recents = loadRecents()
        if let entry = recents.first(where: { $0.fileName == fileName }),
           let thumb = entry.thumbnailFileName,
           let dir = thumbnailsDirectory {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(thumb))
        }
        saveRecents(recents.filter { $0.fileName != fileName })
    }

    static func thumbnail(for document: RecentDocument) -> UIImage? {
        guard let name = document.thumbnailFileName,
              let dir = thumbnailsDirectory else { return nil }
        return UIImage(contentsOfFile: dir.appendingPathComponent(name).path)
    }

    private static func sanitizedThumbnailName(for fileName: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = fileName.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        return String(cleaned) + ".png"
    }
}
