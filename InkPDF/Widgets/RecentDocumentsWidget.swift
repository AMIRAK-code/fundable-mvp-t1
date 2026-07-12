//
//  RecentDocumentsWidget.swift
//  InkPDFWidgets
//
//  Home Screen (small / medium / large) and Lock Screen (rectangular)
//  widgets showing recently opened documents. Every document deep-links
//  back into the app via the inkpdf:// URL scheme.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct RecentsEntry: TimelineEntry {
    let date: Date
    let documents: [RecentDocument]
    let isPlaceholder: Bool

    static var sample: RecentsEntry {
        RecentsEntry(
            date: Date(),
            documents: [
                RecentDocument(fileName: "Biology Notes.pdf", displayName: "Biology Notes",
                               lastOpened: Date(), pageIndex: 11, pageCount: 42, thumbnailFileName: nil),
                RecentDocument(fileName: "Research Paper.pdf", displayName: "Research Paper",
                               lastOpened: Date(), pageIndex: 3, pageCount: 18, thumbnailFileName: nil),
                RecentDocument(fileName: "Lecture Slides.pdf", displayName: "Lecture Slides",
                               lastOpened: Date(), pageIndex: 0, pageCount: 96, thumbnailFileName: nil),
                RecentDocument(fileName: "Workbook.pdf", displayName: "Workbook",
                               lastOpened: Date(), pageIndex: 7, pageCount: 30, thumbnailFileName: nil)
            ],
            isPlaceholder: true)
    }
}

struct RecentsProvider: TimelineProvider {

    func placeholder(in context: Context) -> RecentsEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentsEntry) -> Void) {
        completion(currentEntry(preview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentsEntry>) -> Void) {
        // The app reloads timelines whenever documents are opened or saved.
        completion(Timeline(entries: [currentEntry(preview: false)], policy: .never))
    }

    private func currentEntry(preview: Bool) -> RecentsEntry {
        let recents = SharedStore.loadRecents()
        if recents.isEmpty && preview {
            return .sample
        }
        return RecentsEntry(date: Date(), documents: recents, isPlaceholder: false)
    }
}

// MARK: - Views

struct RecentDocumentsWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: RecentsEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            accessoryRectangular
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        Group {
            if let doc = entry.documents.first {
                VStack(alignment: .leading, spacing: 6) {
                    thumbnail(for: doc)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(doc.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(doc.progressText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .widgetURL(doc.openURL)
            } else {
                emptyState
            }
        }
    }

    // MARK: Medium

    private var mediumView: some View {
        Group {
            if entry.documents.isEmpty {
                emptyState
            } else {
                HStack(spacing: 12) {
                    ForEach(entry.documents.prefix(3)) { doc in
                        Link(destination: doc.openURL) {
                            VStack(spacing: 5) {
                                thumbnail(for: doc)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                Text(doc.displayName)
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Large

    private var largeView: some View {
        Group {
            if entry.documents.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Recent PDFs", systemImage: "pencil.and.outline")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Link(destination: importURL) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.tint)
                        }
                    }
                    ForEach(entry.documents.prefix(4)) { doc in
                        Link(destination: doc.openURL) {
                            HStack(spacing: 12) {
                                thumbnail(for: doc)
                                    .frame(width: 40, height: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.displayName)
                                        .font(.footnote.weight(.semibold))
                                        .lineLimit(1)
                                    Text(doc.progressText)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Lock Screen

    private var accessoryRectangular: some View {
        Group {
            if let doc = entry.documents.first {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.and.outline")
                        Text("InkPDF")
                            .font(.caption2.weight(.semibold))
                    }
                    Text(doc.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(doc.progressText)
                        .font(.caption2)
                }
                .widgetURL(doc.openURL)
            } else {
                VStack(alignment: .leading) {
                    Text("InkPDF")
                        .font(.headline)
                    Text("No recent documents")
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: Pieces

    private func thumbnail(for doc: RecentDocument) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.quaternary)
            if !entry.isPlaceholder, let image = SharedStore.thumbnail(for: doc) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "doc.richtext")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "pencil.and.outline")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("Open a PDF in InkPDF to see it here")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var importURL: URL {
        URL(string: "\(SharedStore.urlScheme)://import")!
    }
}

// MARK: - Widget

struct RecentDocumentsWidget: Widget {
    let kind = "InkPDF.RecentDocuments"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentsProvider()) { entry in
            RecentDocumentsWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Recent PDFs")
        .description("Jump back into the documents you were reading and annotating.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}
