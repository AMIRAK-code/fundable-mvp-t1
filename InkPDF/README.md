# InkPDF — read, study, and mark up PDFs on iPhone & iPad

A complete, clonable Xcode project for iOS and iPadOS. InkPDF is a
PDF reader and annotator in the spirit of the well-known note-taking
apps: **vector** ink with finger or Apple Pencil, typed text boxes,
photo insertion, text highlighting, notebooks, and Home/Lock Screen
widgets that jump straight back into your recent documents.

Everything is native Apple frameworks — PDFKit, PencilKit, SwiftUI,
UIKit, WidgetKit. No third-party dependencies, no package resolution:
clone, open, run.

## Getting started

1. Open `InkPDF/InkPDF.xcodeproj` in Xcode 15 or newer.
2. Select the **InkPDF** target → *Signing & Capabilities* → pick your
   **Team**. Do the same for the **InkPDFWidgetsExtension** target.
3. If Xcode complains about bundle identifiers being taken, change
   `com.inkpdf.app` and `com.inkpdf.app.widgets` to your own reverse-DNS
   ids (keep the widget id prefixed by the app id).
4. **App Group (for widgets):** the app and widget share data through
   the App Group `group.com.inkpdf.shared`. Under your own team you'll
   likely need your own group id. Change it in three places:
   - `Shared/RecentDocumentsStore.swift` → `SharedStore.appGroupID`
   - `App/InkPDF.entitlements`
   - `Widgets/InkPDFWidgets.entitlements`
   The app works fine without the group configured — only the widgets
   stay empty until it is.
5. Build & run on an iPhone or iPad (simulator works; Apple Pencil
   obviously needs real hardware).

A "Welcome to InkPDF" document is generated on first launch so you can
try every tool immediately.

## Features

### Reading
- Fast continuous scrolling and zooming (PDFKit), page thumbnails
  sidebar, find-in-document, go-to-page, remembers your last page.
- Import PDFs from Files/iCloud, receive them via "Open in InkPDF",
  and manage the library (rename, duplicate, delete, share).
- Documents are visible in the Files app (file sharing is enabled).

### Vector ink (finger, Apple Pencil, or mouse/trackpad)
- Full PencilKit tool picker: pen, marker, pencil, eraser, ruler and
  lasso, with pressure & tilt on Apple Pencil.
- Strokes live on a canvas overlay that PDFKit keeps perfectly
  registered with each page while you zoom and scroll.
- On save, strokes are written into the PDF as **vector ink
  annotations** (bezier paths — resolution independent, visible in any
  PDF viewer), *and* the raw PencilKit drawing is archived inside the
  PDF so your ink stays fully editable next time you open the file.
- Optional "Apple Pencil only" mode so your palm/finger scrolls
  instead of drawing.

### Text markup
- Select text in Read mode, then highlight / underline / strikethrough
  in your chosen color (standard PDF markup annotations).

### Typed notes
- Edit mode: tap anywhere to type a text box (font size + color),
  tap to edit, long-press-drag to move, delete from the editor.

### Pictures
- Insert photos from your library onto any page; drag to move,
  tap for larger/smaller/delete.

### Pages & notebooks
- Create notebooks with blank / lined / grid / dotted paper (A4 or US
  Letter), and append blank pages to any document — great for taking
  notes alongside a paper you're reading.

### Widgets
- Home Screen widgets (small / medium / large) and a Lock Screen
  widget showing your recent documents with thumbnails and reading
  progress. Tapping one deep-links straight into that document; the
  large widget also has a shortcut to import a new PDF.

### Saving & sharing
- Autosave (debounced) into the PDF file itself, plus save on close
  and on backgrounding. Undo/redo for ink and annotations.
- Share either the annotated PDF, or a **flattened export** where ink
  (still vector), highlights, text boxes, and images are burned into
  the page content so it renders identically everywhere.

## Project layout

```
InkPDF/
├── InkPDF.xcodeproj/            Hand-authored project, two targets
├── App/                         iOS/iPadOS app target
│   ├── InkPDFApp.swift          SwiftUI entry point + deep links
│   ├── AppModel.swift           Library, import/rename/delete, routing
│   ├── LibraryView.swift        Document grid, notebook sheet
│   ├── NotebookFactory.swift    Generated welcome doc + paper styles
│   ├── ReaderView.swift         SwiftUI ⇄ UIKit bridge
│   ├── PDFReaderViewController.swift   Reader: modes, tools, saving
│   ├── CanvasOverlayCoordinator.swift  PencilKit overlay per PDF page
│   ├── DrawingArchive.swift     Ink/image persistence inside the PDF,
│   │                            flattened export
│   ├── InkConversion.swift      PKStroke → vector PDF ink annotation
│   ├── ImageStampAnnotation.swift      Picture annotations
│   └── TextAnnotationEditor.swift      Text box editor sheet
├── Widgets/                     WidgetKit extension target
│   ├── InkPDFWidgetBundle.swift
│   └── RecentDocumentsWidget.swift
└── Shared/
    └── RecentDocumentsStore.swift      App-Group store (recents,
                                        thumbnails, deep-link URLs)
```

## How annotations are stored (worth knowing)

| Annotation | In the saved PDF | In other viewers |
|---|---|---|
| Ink | Vector `.ink` annotations + hidden editable archive | ✅ visible (vector) |
| Highlight/underline/strikethrough | Standard markup annotations | ✅ visible |
| Text boxes | Standard `FreeText` annotations | ✅ visible |
| Images | Hidden archive (bytes + placement) | ⚠️ only in InkPDF — use **Share → Flattened PDF** for a copy with images visible everywhere |

PDFKit cannot author appearance streams for image stamps, so inserted
pictures ride along in a hidden archive annotation and are re-created
live when InkPDF reopens the file. The flattened export burns them in
for universal viewing.

## Requirements

- Xcode 15+ (project format), iOS/iPadOS **17.0+** deployment target.
- Works on iPhone and iPad; Apple Pencil supported but optional.
