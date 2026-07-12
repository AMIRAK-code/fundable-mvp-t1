//
//  PDFReaderViewController.swift
//  InkPDF
//
//  The reader/annotator screen:
//
//  • Read mode     — scroll, zoom, select text, tap links, search.
//  • Mark Up mode  — PencilKit vector ink over every page (finger or
//                    Apple Pencil), with the full PencilKit tool picker.
//  • Edit mode     — tap to type text boxes, drag to move text/images,
//                    tap images to resize/delete, long-press to drag.
//
//  Plus: text-selection highlights/underline/strikethrough, image
//  insertion from the photo library, page thumbnails, find-in-document,
//  go-to-page, appending blank pages, autosave into the PDF file, and
//  flattened export for sharing.
//

import PDFKit
import PencilKit
import PhotosUI
import UIKit

final class PDFReaderViewController: UIViewController {

    enum Mode: Int {
        case read = 0
        case markUp = 1
        case edit = 2
    }

    // MARK: - State

    let fileURL: URL
    var onClose: (() -> Void)?

    private var document: PDFDocument?
    private let pdfView = PDFView()
    private let thumbnailView = PDFThumbnailView()
    private var thumbnailWidthConstraint: NSLayoutConstraint?
    private var isThumbnailSidebarVisible = false

    private let overlay = CanvasOverlayCoordinator()

    private var mode: Mode = .read {
        didSet { applyMode() }
    }

    private var markupColor: UIColor {
        get {
            guard let data = UserDefaults.standard.data(forKey: "io.inkpdf.markupColor"),
                  let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
                return .systemYellow
            }
            return color
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: "io.inkpdf.markupColor")
            }
        }
    }

    private var isDirty = false
    private var didReportSaveError = false
    private var saveTimer: Timer?

    private var draggedAnnotation: PDFAnnotation?
    private var dragOffset: CGPoint = .zero
    private var dragStartBounds: CGRect = .zero

    private var isViewVisible = false
    private var deferredPresentations: [() -> Void] = []

    // MARK: - Controls

    private let modeControl = UISegmentedControl(items: ["Read", "Mark Up", "Edit"])
    private let colorWell = UIColorWell()
    private var markupMenuItem: UIBarButtonItem!
    private var pageIndicatorButton: UIButton!
    private var observers: [NSObjectProtocol] = []

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recognizer.delegate = self
        recognizer.isEnabled = false
        return recognizer
    }()

    private lazy var dragRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        recognizer.minimumPressDuration = 0.2
        recognizer.delegate = self
        recognizer.isEnabled = false
        return recognizer
    }()

    // MARK: - Lifecycle

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        saveTimer?.invalidate()
        observers.forEach(NotificationCenter.default.removeObserver(_:))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = fileURL.deletingPathExtension().lastPathComponent

        configureNavigationItems()
        configureLayout()
        configureToolbar()
        loadDocument()
        observeNotifications()
        applyMode()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        let pending = deferredPresentations
        deferredPresentations.removeAll()
        pending.forEach { $0() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNow(withThumbnail: true)
    }

    /// Present alerts only once the view is actually on screen.
    private func presentWhenVisible(_ action: @escaping () -> Void) {
        if isViewVisible {
            action()
        } else {
            deferredPresentations.append(action)
        }
    }

    // MARK: - Setup

    private func loadDocument() {
        guard let document = PDFDocument(url: fileURL) else {
            presentWhenVisible { [weak self] in
                self?.presentAlert(title: "Could Not Open Document",
                                   message: "The file does not appear to be a readable PDF.") {
                    self?.closeReader()
                }
            }
            return
        }

        if document.isLocked {
            promptForPassword(document: document)
            return
        }
        attach(document: document)
    }

    private func attach(document: PDFDocument) {
        self.document = document

        // Pull editable ink/images out of the file's hidden archives.
        let drawings = DrawingArchive.restore(document: document)
        overlay.preloadDrawings(drawings)
        overlay.onDrawingChanged = { [weak self] in
            self?.markDirty()
        }

        pdfView.pageOverlayViewProvider = overlay
        pdfView.document = document
        thumbnailView.pdfView = pdfView

        // Resume at the last-read page if we have one on record.
        let fileName = fileURL.lastPathComponent
        if let entry = SharedStore.loadRecents().first(where: { $0.fileName == fileName }),
           entry.pageIndex > 0,
           let page = document.page(at: min(entry.pageIndex, document.pageCount - 1)) {
            DispatchQueue.main.async { [weak self] in
                self?.pdfView.go(to: page)
            }
        }
        updatePageIndicator()
    }

    private func promptForPassword(document: PDFDocument) {
        presentWhenVisible { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Password Required",
                                          message: "This PDF is encrypted.",
                                          preferredStyle: .alert)
            alert.addTextField { $0.isSecureTextEntry = true; $0.placeholder = "Password" }
            alert.addAction(UIAlertAction(title: "Unlock", style: .default) { [weak self] _ in
                let password = alert.textFields?.first?.text ?? ""
                if document.unlock(withPassword: password) {
                    self?.attach(document: document)
                } else {
                    self?.promptForPassword(document: document)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.closeReader()
            })
            self.present(alert, animated: true)
        }
    }

    private func configureLayout() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.pageShadowsEnabled = true
        pdfView.isFindInteractionEnabled = true
        pdfView.addGestureRecognizer(tapRecognizer)
        pdfView.addGestureRecognizer(dragRecognizer)

        let sidebar = UIView()
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        sidebar.backgroundColor = .secondarySystemBackground

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.layoutMode = .vertical
        thumbnailView.thumbnailSize = CGSize(width: 90, height: 120)
        thumbnailView.backgroundColor = .clear
        sidebar.addSubview(thumbnailView)

        view.addSubview(sidebar)
        view.addSubview(pdfView)

        let widthConstraint = sidebar.widthAnchor.constraint(equalToConstant: 0)
        thumbnailWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            sidebar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sidebar.topAnchor.constraint(equalTo: view.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            widthConstraint,

            thumbnailView.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            thumbnailView.topAnchor.constraint(equalTo: sidebar.safeAreaLayoutGuide.topAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: sidebar.safeAreaLayoutGuide.bottomAnchor),

            pdfView.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(closeTapped)),
            UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"),
                            style: .plain, target: self, action: #selector(undoTapped)),
            UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward"),
                            style: .plain, target: self, action: #selector(redoTapped))
        ]

        let shareMenu = UIMenu(children: [
            UIAction(title: "Flattened PDF",
                     subtitle: "Annotations burned in — looks the same everywhere",
                     image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                self?.shareFlattened()
            },
            UIAction(title: "Document with Annotations",
                     image: UIImage(systemName: "doc.badge.ellipsis")) { [weak self] _ in
                self?.shareOriginal()
            }
        ])
        let shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), menu: shareMenu)

        let moreItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: makeMoreMenu())

        navigationItem.rightBarButtonItems = [moreItem, shareItem]
    }

    private func makeMoreMenu() -> UIMenu {
        UIMenu(children: [
            UIDeferredMenuElement.uncached { [weak self] completion in
                guard let self else { return completion([]) }
                completion([
                    UIAction(title: "Find in Document",
                             image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
                        self?.pdfView.findInteraction.presentFindNavigator(showingReplace: false)
                    },
                    UIAction(title: "Go to Page…",
                             image: UIImage(systemName: "number")) { [weak self] _ in
                        self?.promptGoToPage()
                    },
                    UIAction(title: "Page Thumbnails",
                             image: UIImage(systemName: "sidebar.left"),
                             state: self.isThumbnailSidebarVisible ? .on : .off) { [weak self] _ in
                        self?.toggleThumbnailSidebar()
                    },
                    UIMenu(options: .displayInline, children: [
                        UIAction(title: "Add Blank Page After This",
                                 image: UIImage(systemName: "plus.rectangle.portrait")) { [weak self] _ in
                            self?.addBlankPage()
                        },
                        UIAction(title: "Clear Ink on This Page",
                                 image: UIImage(systemName: "eraser"),
                                 attributes: .destructive) { [weak self] _ in
                            self?.clearInkOnCurrentPage()
                        }
                    ]),
                    UIMenu(options: .displayInline, children: [
                        UIAction(title: "Draw with Apple Pencil Only",
                                 image: UIImage(systemName: "applepencil"),
                                 state: self.overlay.drawingPolicy == .pencilOnly ? .on : .off) { [weak self] _ in
                            guard let self else { return }
                            self.overlay.drawingPolicy =
                                self.overlay.drawingPolicy == .pencilOnly ? .anyInput : .pencilOnly
                        }
                    ])
                ])
            }
        ])
    }

    private func configureToolbar() {
        navigationController?.isToolbarHidden = false

        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)

        colorWell.selectedColor = markupColor
        colorWell.supportsAlpha = false
        colorWell.title = "Markup Color"
        colorWell.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)

        let markupMenu = UIMenu(children: [
            UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { [weak self] _ in
                self?.applyMarkup(.highlight)
            },
            UIAction(title: "Underline", image: UIImage(systemName: "underline")) { [weak self] _ in
                self?.applyMarkup(.underline)
            },
            UIAction(title: "Strikethrough", image: UIImage(systemName: "strikethrough")) { [weak self] _ in
                self?.applyMarkup(.strikeOut)
            }
        ])
        markupMenuItem = UIBarButtonItem(image: UIImage(systemName: "highlighter"), menu: markupMenu)
        markupMenuItem.isEnabled = false

        let photoItem = UIBarButtonItem(image: UIImage(systemName: "photo"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(insertImageTapped))

        pageIndicatorButton = UIButton(type: .system)
        pageIndicatorButton.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        pageIndicatorButton.addTarget(self, action: #selector(promptGoToPage), for: .touchUpInside)

        toolbarItems = [
            UIBarButtonItem(customView: modeControl),
            .flexibleSpace(),
            markupMenuItem,
            UIBarButtonItem(customView: colorWell),
            photoItem,
            .flexibleSpace(),
            UIBarButtonItem(customView: pageIndicatorButton)
        ]
    }

    private func observeNotifications() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .PDFViewPageChanged,
                                            object: pdfView,
                                            queue: .main) { [weak self] _ in
            self?.pageDidChange()
        })
        observers.append(center.addObserver(forName: .PDFViewSelectionChanged,
                                            object: pdfView,
                                            queue: .main) { [weak self] _ in
            guard let self else { return }
            self.markupMenuItem.isEnabled = !(self.pdfView.currentSelection?.string ?? "").isEmpty
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                            object: nil,
                                            queue: .main) { [weak self] _ in
            self?.saveNow(withThumbnail: true)
        })
    }

    // MARK: - Modes

    private func applyMode() {
        let isMarkUp = mode == .markUp
        pdfView.isInMarkupMode = isMarkUp
        overlay.setInteractive(isMarkUp)
        if isMarkUp {
            overlay.beginDrawing(on: pdfView.currentPage)
        } else {
            overlay.endDrawing()
        }
        tapRecognizer.isEnabled = mode == .edit
        dragRecognizer.isEnabled = mode == .edit
        pdfView.clearSelection()
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        mode = Mode(rawValue: sender.selectedSegmentIndex) ?? .read
    }

    @objc private func colorWellChanged(_ sender: UIColorWell) {
        if let color = sender.selectedColor {
            markupColor = color
        }
    }

    private func pageDidChange() {
        updatePageIndicator()
        if mode == .markUp {
            overlay.focusCanvas(for: pdfView.currentPage)
        }
        // Keep the widget's "continue reading" page in sync (cheap: no thumbnail).
        if let document, let page = pdfView.currentPage {
            SharedStore.touch(fileName: fileURL.lastPathComponent,
                              displayName: fileURL.deletingPathExtension().lastPathComponent,
                              pageIndex: document.index(for: page),
                              pageCount: document.pageCount,
                              thumbnail: nil)
        }
    }

    private func updatePageIndicator() {
        guard let document, let page = pdfView.currentPage else {
            pageIndicatorButton?.setTitle("– / –", for: .normal)
            return
        }
        let index = document.index(for: page)
        pageIndicatorButton?.setTitle("\(index + 1) / \(document.pageCount)", for: .normal)
    }

    // MARK: - Undo / Redo

    private var activeUndoManager: UndoManager? {
        view.window?.undoManager ?? undoManager
    }

    @objc private func undoTapped() {
        activeUndoManager?.undo()
        markDirty()
    }

    @objc private func redoTapped() {
        activeUndoManager?.redo()
        markDirty()
    }

    private func add(annotation: PDFAnnotation, to page: PDFPage) {
        page.addAnnotation(annotation)
        activeUndoManager?.registerUndo(withTarget: self) { target in
            target.remove(annotation: annotation, from: page)
        }
        markDirty()
    }

    private func remove(annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
        activeUndoManager?.registerUndo(withTarget: self) { target in
            target.add(annotation: annotation, to: page)
        }
        markDirty()
    }

    private func move(annotation: PDFAnnotation, to newBounds: CGRect, on page: PDFPage) {
        let oldBounds = annotation.bounds
        annotation.bounds = newBounds
        activeUndoManager?.registerUndo(withTarget: self) { target in
            target.move(annotation: annotation, to: oldBounds, on: page)
        }
        markDirty()
    }

    // MARK: - Text-selection markup

    private func applyMarkup(_ subtype: PDFAnnotationSubtype) {
        guard let selection = pdfView.currentSelection else { return }
        let color = markupColor
        for lineSelection in selection.selectionsByLine() {
            for page in lineSelection.pages {
                let bounds = lineSelection.bounds(for: page)
                guard !bounds.isNull, !bounds.isEmpty else { continue }
                let annotation = PDFAnnotation(bounds: bounds, forType: subtype, withProperties: nil)
                annotation.color = color
                add(annotation: annotation, to: page)
            }
        }
        pdfView.clearSelection()
    }

    // MARK: - Edit mode: text boxes, moving, images

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard mode == .edit, recognizer.state == .ended else { return }
        let viewPoint = recognizer.location(in: pdfView)
        guard let page = pdfView.page(for: viewPoint, nearest: true) else { return }
        let pagePoint = pdfView.convert(viewPoint, to: page)

        if let annotation = editableAnnotation(at: pagePoint, on: page) {
            if let image = annotation as? ImageStampAnnotation {
                presentImageActions(for: image, on: page)
            } else if annotation.type?.caseInsensitiveCompare("FreeText") == .orderedSame {
                editTextAnnotation(annotation, on: page)
            } else {
                presentDeleteAction(for: annotation, on: page)
            }
        } else {
            createTextAnnotation(at: pagePoint, on: page)
        }
    }

    /// Annotations the Edit mode is allowed to touch.
    private func editableAnnotation(at point: CGPoint, on page: PDFPage) -> PDFAnnotation? {
        let editableTypes = ["freetext", "highlight", "underline", "strikeout", "square", "circle", "ink", "stamp"]
        // Search a small neighborhood so thin annotations are tappable.
        let probes = [CGPoint(x: point.x, y: point.y),
                      CGPoint(x: point.x + 4, y: point.y + 4),
                      CGPoint(x: point.x - 4, y: point.y - 4)]
        for probe in probes {
            if let annotation = page.annotation(at: probe),
               annotation.shouldDisplay,
               let type = annotation.type?.lowercased(),
               editableTypes.contains(type) {
                return annotation
            }
        }
        return nil
    }

    private func createTextAnnotation(at pagePoint: CGPoint, on page: PDFPage) {
        let editor = TextAnnotationEditorViewController(text: "",
                                                        fontSize: 16,
                                                        color: preferredTextColor(),
                                                        isNewAnnotation: true)
        editor.onFinish = { [weak self] result in
            guard let self, case .commit(let text, let fontSize, let color) = result,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let font = UIFont.systemFont(ofSize: fontSize)
            let bounds = Self.textBounds(for: text, font: font, anchor: pagePoint, page: page)
            let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = font
            annotation.fontColor = color
            annotation.color = .clear
            annotation.userName = AnnotationMarker.textBox
            self.add(annotation: annotation, to: page)
        }
        present(editor.wrappedInSheet(), animated: true)
    }

    private func editTextAnnotation(_ annotation: PDFAnnotation, on page: PDFPage) {
        let currentSize = annotation.font?.pointSize ?? 16
        let editor = TextAnnotationEditorViewController(text: annotation.contents ?? "",
                                                        fontSize: currentSize,
                                                        color: annotation.fontColor ?? preferredTextColor(),
                                                        isNewAnnotation: false)
        editor.onFinish = { [weak self] result in
            guard let self else { return }
            switch result {
            case .commit(let text, let fontSize, let color):
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.remove(annotation: annotation, from: page)
                    return
                }
                let font = UIFont.systemFont(ofSize: fontSize)
                annotation.contents = text
                annotation.font = font
                annotation.fontColor = color
                let anchor = CGPoint(x: annotation.bounds.minX, y: annotation.bounds.maxY)
                annotation.bounds = Self.textBounds(for: text, font: font, anchor: anchor, page: page)
                self.markDirty()
            case .delete:
                self.remove(annotation: annotation, from: page)
            case .cancel:
                break
            }
        }
        present(editor.wrappedInSheet(), animated: true)
    }

    /// Compute freeText bounds so `anchor` is the top-left corner, sized to fit.
    private static func textBounds(for text: String, font: UIFont, anchor: CGPoint, page: PDFPage) -> CGRect {
        let pageBounds = page.bounds(for: .cropBox)
        let maxWidth = max(pageBounds.width - 32, 60)
        let constrained = CGSize(width: maxWidth * 0.8, height: .greatestFiniteMagnitude)
        var size = (text as NSString).boundingRect(with: constrained,
                                                   options: [.usesLineFragmentOrigin],
                                                   attributes: [.font: font],
                                                   context: nil).size
        size.width = min(ceil(size.width) + 14, maxWidth)
        size.height = ceil(size.height) + 12

        var origin = CGPoint(x: anchor.x, y: anchor.y - size.height)
        origin.x = min(max(origin.x, pageBounds.minX), pageBounds.maxX - size.width)
        origin.y = min(max(origin.y, pageBounds.minY), pageBounds.maxY - size.height)
        return CGRect(origin: origin, size: size)
    }

    private func preferredTextColor() -> UIColor {
        // Yellow is a highlight color, not a text color — fall back to red.
        markupColor == .systemYellow ? .systemRed : markupColor
    }

    // MARK: Dragging

    @objc private func handleDrag(_ recognizer: UILongPressGestureRecognizer) {
        let viewPoint = recognizer.location(in: pdfView)
        guard let page = pdfView.page(for: viewPoint, nearest: true) else { return }
        let pagePoint = pdfView.convert(viewPoint, to: page)

        switch recognizer.state {
        case .began:
            let movable = editableAnnotation(at: pagePoint, on: page)
            if let movable,
               movable is ImageStampAnnotation
                || movable.type?.caseInsensitiveCompare("FreeText") == .orderedSame {
                draggedAnnotation = movable
                dragStartBounds = movable.bounds
                dragOffset = CGPoint(x: pagePoint.x - movable.bounds.minX,
                                     y: pagePoint.y - movable.bounds.minY)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }

        case .changed:
            guard let annotation = draggedAnnotation, annotation.page === page else { return }
            let pageBounds = page.bounds(for: .cropBox)
            var origin = CGPoint(x: pagePoint.x - dragOffset.x, y: pagePoint.y - dragOffset.y)
            origin.x = min(max(origin.x, pageBounds.minX - annotation.bounds.width / 2),
                           pageBounds.maxX - annotation.bounds.width / 2)
            origin.y = min(max(origin.y, pageBounds.minY - annotation.bounds.height / 2),
                           pageBounds.maxY - annotation.bounds.height / 2)
            annotation.bounds = CGRect(origin: origin, size: annotation.bounds.size)

        case .ended, .cancelled:
            if let annotation = draggedAnnotation, let page = annotation.page,
               annotation.bounds != dragStartBounds {
                let startBounds = dragStartBounds
                activeUndoManager?.registerUndo(withTarget: self) { target in
                    target.move(annotation: annotation, to: startBounds, on: page)
                }
                markDirty()
            }
            draggedAnnotation = nil

        default:
            break
        }
    }

    // MARK: Images

    @objc private func insertImageTapped() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func insert(image: UIImage) {
        guard let page = pdfView.currentPage else { return }
        let normalized = Self.downscaled(image: image, maxDimension: 1600)
        guard let data = normalized.pngData() else { return }

        let pageBounds = page.bounds(for: .cropBox)
        let targetWidth = pageBounds.width * 0.45
        let aspect = normalized.size.height / max(normalized.size.width, 1)
        let size = CGSize(width: targetWidth, height: targetWidth * aspect)
        let origin = CGPoint(x: pageBounds.midX - size.width / 2,
                             y: pageBounds.midY - size.height / 2)

        let annotation = ImageStampAnnotation(bounds: CGRect(origin: origin, size: size), imageData: data)
        add(annotation: annotation, to: page)

        // Jump to Edit mode so the image can be dragged into place right away.
        modeControl.selectedSegmentIndex = Mode.edit.rawValue
        mode = .edit
    }

    private static func downscaled(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension, largest > 0 else { return image }
        let scale = maxDimension / largest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func presentImageActions(for annotation: ImageStampAnnotation, on page: PDFPage) {
        let sheet = UIAlertController(title: "Image", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Larger", style: .default) { [weak self] _ in
            self?.resize(annotation: annotation, on: page, factor: 1.25)
        })
        sheet.addAction(UIAlertAction(title: "Smaller", style: .default) { [weak self] _ in
            self?.resize(annotation: annotation, on: page, factor: 0.8)
        })
        sheet.addAction(UIAlertAction(title: "Delete Image", style: .destructive) { [weak self] _ in
            self?.remove(annotation: annotation, from: page)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentPopover(sheet, near: annotation)
    }

    private func presentDeleteAction(for annotation: PDFAnnotation, on page: PDFPage) {
        let name = annotation.type ?? "Annotation"
        let sheet = UIAlertController(title: name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.remove(annotation: annotation, from: page)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentPopover(sheet, near: annotation)
    }

    private func resize(annotation: PDFAnnotation, on page: PDFPage, factor: CGFloat) {
        let bounds = annotation.bounds
        let pageBounds = page.bounds(for: .cropBox)
        var newSize = CGSize(width: bounds.width * factor, height: bounds.height * factor)
        let maxWidth = pageBounds.width
        if newSize.width > maxWidth {
            let scale = maxWidth / newSize.width
            newSize = CGSize(width: newSize.width * scale, height: newSize.height * scale)
        }
        if newSize.width < 24 || newSize.height < 24 { return }
        let newBounds = CGRect(x: bounds.midX - newSize.width / 2,
                               y: bounds.midY - newSize.height / 2,
                               width: newSize.width,
                               height: newSize.height)
        move(annotation: annotation, to: newBounds, on: page)
    }

    private func presentPopover(_ alert: UIAlertController, near annotation: PDFAnnotation) {
        if let popover = alert.popoverPresentationController, let page = annotation.page {
            popover.sourceView = pdfView
            let viewBounds = pdfView.convert(annotation.bounds, from: page)
            popover.sourceRect = viewBounds
        }
        present(alert, animated: true)
    }

    // MARK: - Pages

    private func addBlankPage() {
        guard let document, let current = pdfView.currentPage else { return }
        let index = document.index(for: current)
        let newPage = PDFPage()
        newPage.setBounds(current.bounds(for: .mediaBox), for: .mediaBox)
        document.insert(newPage, at: index + 1)
        markDirty()
        updatePageIndicator()
        if let inserted = document.page(at: index + 1) {
            pdfView.go(to: inserted)
        }
    }

    private func clearInkOnCurrentPage() {
        guard let page = pdfView.currentPage else { return }
        overlay.clearDrawing(for: page)
    }

    @objc private func promptGoToPage() {
        guard let document else { return }
        let alert = UIAlertController(title: "Go to Page",
                                      message: "1 – \(document.pageCount)",
                                      preferredStyle: .alert)
        alert.addTextField { $0.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "Go", style: .default) { [weak self] _ in
            guard let self,
                  let text = alert.textFields?.first?.text,
                  let number = Int(text),
                  let page = document.page(at: min(max(number - 1, 0), document.pageCount - 1)) else { return }
            self.pdfView.go(to: page)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func toggleThumbnailSidebar() {
        isThumbnailSidebarVisible.toggle()
        thumbnailWidthConstraint?.constant = isThumbnailSidebarVisible ? 132 : 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Saving

    private func markDirty() {
        isDirty = true
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.saveNow(withThumbnail: false)
        }
    }

    /// Write annotations + hidden editable archives into the PDF file.
    func saveNow(withThumbnail: Bool) {
        saveTimer?.invalidate()
        guard let document, isDirty else {
            if withThumbnail { updateRecentsEntry(includeThumbnail: true) }
            return
        }

        let overlay = self.overlay
        let token = DrawingArchive.install(into: document) { page in
            overlay.drawing(for: page)
        }
        let success = document.write(to: fileURL)
        token.revert()

        if success {
            isDirty = false
        } else if !didReportSaveError {
            didReportSaveError = true
            presentAlert(title: "Could Not Save",
                         message: "The document could not be written. It may be read-only or encrypted with restrictions. Use the share button to export a flattened copy instead.")
        }
        updateRecentsEntry(includeThumbnail: withThumbnail)
    }

    private func updateRecentsEntry(includeThumbnail: Bool) {
        guard let document, let page = pdfView.currentPage else { return }
        var thumbnail: UIImage?
        if includeThumbnail {
            let bounds = page.bounds(for: .cropBox)
            let scale = 360 / max(bounds.width, 1)
            thumbnail = page.thumbnail(of: CGSize(width: bounds.width * scale,
                                                  height: bounds.height * scale),
                                       for: .cropBox)
        }
        SharedStore.touch(fileName: fileURL.lastPathComponent,
                          displayName: fileURL.deletingPathExtension().lastPathComponent,
                          pageIndex: document.index(for: page),
                          pageCount: document.pageCount,
                          thumbnail: thumbnail)
    }

    // MARK: - Sharing

    private func shareFlattened() {
        guard let document else { return }
        saveNow(withThumbnail: false)
        let overlay = self.overlay
        let data = DrawingArchive.flattenedData(document: document) { page in
            overlay.drawing(for: page)
        }
        let name = fileURL.deletingPathExtension().lastPathComponent + " (Annotated).pdf"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: exportURL, options: .atomic)
            presentShareSheet(for: exportURL)
        } catch {
            presentAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }

    private func shareOriginal() {
        saveNow(withThumbnail: false)
        presentShareSheet(for: fileURL)
    }

    private func presentShareSheet(for url: URL) {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(controller, animated: true)
    }

    // MARK: - Closing

    @objc private func closeTapped() {
        closeReader()
    }

    private func closeReader() {
        saveNow(withThumbnail: true)
        onClose?()
    }

    // MARK: - Helpers

    private func presentAlert(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onDismiss?() })
        present(alert, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PDFReaderViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard mode == .edit else { return false }
        if gestureRecognizer === dragRecognizer {
            // Only start a drag on top of a movable annotation.
            let viewPoint = gestureRecognizer.location(in: pdfView)
            guard let page = pdfView.page(for: viewPoint, nearest: true) else { return false }
            let pagePoint = pdfView.convert(viewPoint, to: page)
            guard let annotation = editableAnnotation(at: pagePoint, on: page) else { return false }
            return annotation is ImageStampAnnotation
                || annotation.type?.caseInsensitiveCompare("FreeText") == .orderedSame
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === tapRecognizer
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PDFReaderViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.insert(image: image)
            }
        }
    }
}
