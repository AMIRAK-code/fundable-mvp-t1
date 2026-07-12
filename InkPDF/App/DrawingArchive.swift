//
//  DrawingArchive.swift
//  InkPDF
//
//  Persists editable annotation state *inside* the PDF file itself, so a
//  document carries everything with it:
//
//  • Ink        → visible vector `.ink` annotations (readable in any PDF
//                 viewer) + a hidden per-page archive of the raw PKDrawing
//                 so strokes stay fully editable when reopened in InkPDF.
//  • Images     → hidden per-page archive with the image bytes + placement.
//  • Text boxes → standard freeText annotations (no archive needed).
//  • Highlights → standard markup annotations (no archive needed).
//
//  Also builds the flattened export, where all annotations are burned
//  into the page content for perfect rendering in every viewer.
//

import PDFKit
import PencilKit
import UIKit

/// Placement + bytes of one inserted image, as stored in the hidden archive.
struct ImagePayload: Codable {
    var id: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var png: Data

    init(annotation: ImageStampAnnotation) {
        id = annotation.imageID
        x = annotation.bounds.origin.x
        y = annotation.bounds.origin.y
        width = annotation.bounds.width
        height = annotation.bounds.height
        png = annotation.imageData
    }

    var bounds: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

enum DrawingArchive {

    // MARK: - Restore (on open)

    /// Result of restoring a page: the editable drawing (if any) and the
    /// reconstructed image annotations (already added back to the page).
    struct RestoredPage {
        var drawing: PKDrawing?
    }

    /// Walk the document, pull the editable state out of the hidden archives,
    /// strip InkPDF-generated annotations (they will be regenerated on save),
    /// and re-add live image annotations.
    static func restore(document: PDFDocument) -> [ObjectIdentifier: PKDrawing] {
        var drawings: [ObjectIdentifier: PKDrawing] = [:]

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            var imagePayloads: [ImagePayload] = []

            for annotation in page.annotations {
                guard let marker = annotation.userName else { continue }
                switch marker {
                case AnnotationMarker.drawingArchive:
                    if let contents = annotation.contents,
                       let data = Data(base64Encoded: contents),
                       let drawing = try? PKDrawing(data: data) {
                        drawings[ObjectIdentifier(page)] = drawing
                    }
                    page.removeAnnotation(annotation)

                case AnnotationMarker.imageArchive:
                    if let contents = annotation.contents,
                       let data = Data(base64Encoded: contents),
                       let payloads = try? JSONDecoder().decode([ImagePayload].self, from: data) {
                        imagePayloads.append(contentsOf: payloads)
                    }
                    page.removeAnnotation(annotation)

                case AnnotationMarker.bakedInk:
                    // Regenerated from the restored PKDrawing on save.
                    page.removeAnnotation(annotation)

                default:
                    if marker.hasPrefix(AnnotationMarker.imagePrefix) {
                        // A stale serialized stamp; replaced by the live
                        // ImageStampAnnotation reconstructed below.
                        page.removeAnnotation(annotation)
                    }
                }
            }

            for payload in imagePayloads {
                let annotation = ImageStampAnnotation(bounds: payload.bounds,
                                                      imageData: payload.png,
                                                      imageID: payload.id)
                page.addAnnotation(annotation)
            }
        }

        return drawings
    }

    // MARK: - Install (on save)

    /// Undo token returned by `install`. Call `revert()` right after
    /// `document.write(...)` so the in-memory document goes back to its live
    /// editing state (canvas overlays keep rendering the ink; image stamps
    /// come back as real annotations).
    struct InstallToken {
        fileprivate var addedAnnotations: [(PDFPage, PDFAnnotation)] = []
        fileprivate var removedImageAnnotations: [(PDFPage, ImageStampAnnotation)] = []

        func revert() {
            for (page, annotation) in addedAnnotations {
                page.removeAnnotation(annotation)
            }
            for (page, annotation) in removedImageAnnotations {
                page.addAnnotation(annotation)
            }
        }
    }

    /// Prepare the document for writing:
    /// bake vector ink + attach hidden archives + swap live image stamps
    /// for their archived representation.
    static func install(into document: PDFDocument,
                        drawingProvider: (PDFPage) -> PKDrawing?) -> InstallToken {
        var token = InstallToken()

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }

            // 1. Vector ink annotations + editable drawing archive.
            if let drawing = drawingProvider(page), !drawing.strokes.isEmpty {
                for annotation in InkConversion.bake(drawing: drawing, onto: page) {
                    token.addedAnnotations.append((page, annotation))
                }
                let archive = hiddenArchiveAnnotation(marker: AnnotationMarker.drawingArchive,
                                                      payload: drawing.dataRepresentation())
                page.addAnnotation(archive)
                token.addedAnnotations.append((page, archive))
            }

            // 2. Images: archive bytes + placement, drop the live stamps
            //    (a serialized stamp has no appearance in other viewers,
            //    so we keep the written file clean instead).
            let imageAnnotations = page.annotations.compactMap { $0 as? ImageStampAnnotation }
            if !imageAnnotations.isEmpty {
                let payloads = imageAnnotations.map(ImagePayload.init)
                if let data = try? JSONEncoder().encode(payloads) {
                    let archive = hiddenArchiveAnnotation(marker: AnnotationMarker.imageArchive,
                                                          payload: data)
                    page.addAnnotation(archive)
                    token.addedAnnotations.append((page, archive))
                }
                for annotation in imageAnnotations {
                    page.removeAnnotation(annotation)
                    token.removedImageAnnotations.append((page, annotation))
                }
            }
        }

        return token
    }

    private static func hiddenArchiveAnnotation(marker: String, payload: Data) -> PDFAnnotation {
        let annotation = PDFAnnotation(bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                                       forType: .stamp,
                                       withProperties: nil)
        annotation.userName = marker
        annotation.contents = payload.base64EncodedString()
        annotation.shouldDisplay = false
        annotation.shouldPrint = false
        return annotation
    }

    // MARK: - Flattened export

    /// Render the live document (page content + every annotation + live ink
    /// canvases) into a brand-new PDF where everything is part of the page
    /// content. Strokes are drawn as vector paths, never rasterized.
    static func flattenedData(document: PDFDocument,
                              drawingProvider: (PDFPage) -> PKDrawing?) -> Data {
        let firstBounds = document.page(at: 0)?.bounds(for: .cropBox)
            ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: firstBounds.size))

        return renderer.pdfData { context in
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { continue }
                let pageBounds = page.bounds(for: .cropBox)
                context.beginPage(withBounds: CGRect(origin: .zero, size: pageBounds.size), pageInfo: [:])

                let cg = context.cgContext
                cg.saveGState()
                // UIKit's PDF context is top-left based; flip into PDF space.
                cg.translateBy(x: 0, y: pageBounds.size.height)
                cg.scaleBy(x: 1, y: -1)

                // 1. Original page content, with annotations suppressed so we
                //    control exactly what is drawn on top (no double drawing).
                let annotations = page.annotations
                let previousVisibility = annotations.map { $0.shouldDisplay }
                annotations.forEach { $0.shouldDisplay = false }
                page.draw(with: .cropBox, to: cg)
                for (annotation, visible) in zip(annotations, previousVisibility) {
                    annotation.shouldDisplay = visible
                }

                // 2. Every visible annotation (highlights, text boxes, image
                //    stamps via their custom draw, third-party annotations…).
                for annotation in annotations where annotation.shouldDisplay {
                    annotation.draw(with: .cropBox, in: cg)
                }

                // 3. Live PencilKit ink as vector paths.
                if let drawing = drawingProvider(page), !drawing.strokes.isEmpty {
                    InkConversion.draw(drawing, pageBounds: pageBounds, in: cg)
                }

                cg.restoreGState()
            }
        }
    }
}
