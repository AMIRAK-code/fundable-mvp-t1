//
//  LibraryView.swift
//  InkPDF
//
//  The document library: a grid of all PDFs in the app's Documents folder,
//  with import, notebook creation, rename/duplicate/delete, and the
//  full-screen reader presentation.
//

import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel

    @State private var showNotebookSheet = false
    @State private var renameTarget: DocumentItem?
    @State private var renameText = ""
    @State private var deleteTarget: DocumentItem?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)]

    var body: some View {
        NavigationStack {
            Group {
                if model.documents.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(model.documents) { item in
                                DocumentCell(item: item)
                                    .onTapGesture { model.open(url: item.url) }
                                    .contextMenu { contextMenu(for: item) }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("InkPDF")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showNotebookSheet = true
                    } label: {
                        Label("New Notebook", systemImage: "square.and.pencil")
                    }
                    Button {
                        model.showImporter = true
                    } label: {
                        Label("Import PDF", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .fileImporter(isPresented: $model.showImporter,
                      allowedContentTypes: [UTType.pdf],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                model.importPDFs(from: urls, openFirst: urls.count == 1)
            }
        }
        .sheet(isPresented: $showNotebookSheet) {
            NewNotebookSheet()
                .environmentObject(model)
        }
        .fullScreenCover(item: $model.openedDocument) { opened in
            ReaderContainer(url: opened.url) {
                model.readerDidClose()
            }
            .ignoresSafeArea()
        }
        .alert("Rename Document", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Rename") {
                if let target = renameTarget {
                    model.rename(target, to: renameText)
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
        .alert("Delete “\(deleteTarget?.name ?? "")”?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    model.delete(target)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: {
            Text("This also removes all of its annotations. This cannot be undone.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func contextMenu(for item: DocumentItem) -> some View {
        Button {
            model.open(url: item.url)
        } label: {
            Label("Open", systemImage: "book")
        }
        Button {
            renameText = item.name
            renameTarget = item
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        Button {
            model.duplicate(item)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        ShareLink(item: item.url) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Divider()
        Button(role: .destructive) {
            deleteTarget = item
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Documents", systemImage: "doc.richtext")
        } description: {
            Text("Import a PDF or create a notebook to get started.")
        } actions: {
            Button("Import PDF") { model.showImporter = true }
                .buttonStyle(.borderedProminent)
            Button("New Notebook") { showNotebookSheet = true }
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Grid cell

struct DocumentCell: View {
    let item: DocumentItem

    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 190)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1))
            )
            .shadow(color: .black.opacity(0.12), radius: 5, y: 3)

            Text(item.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(item.modified, format: .dateTime.day().month().year())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .task(id: item.modified) {
            thumbnail = await Self.loadThumbnail(for: item.url)
        }
    }

    private static func loadThumbnail(for url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: 0) else { return nil }
            let bounds = page.bounds(for: .cropBox)
            let scale = 340 / max(bounds.width, 1)
            return page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale),
                                  for: .cropBox)
        }.value
    }
}

// MARK: - New notebook sheet

struct NewNotebookSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = "My Notebook"
    @State private var style: PaperStyle = .lined
    @State private var pageSize: NotebookPageSize = .a4
    @State private var pageCount = 20

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Notebook name", text: $name)
                }
                Section("Paper") {
                    Picker("Style", selection: $style) {
                        ForEach(PaperStyle.allCases) { style in
                            Label(style.title, systemImage: style.symbolName).tag(style)
                        }
                    }
                    Picker("Page size", selection: $pageSize) {
                        ForEach(NotebookPageSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    Stepper("Pages: \(pageCount)", value: $pageCount, in: 1...100)
                }
            }
            .navigationTitle("New Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        model.createNotebook(name: name, style: style, pageSize: pageSize, pageCount: pageCount)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
