//
//  InkConversion.swift
//  InkPDF
//
//  Converts PencilKit strokes into vector PDF ink annotations (and draws
//  them straight into a CGContext for flattened exports). The stroke
//  geometry is preserved as bezier paths, so the resulting PDF ink is
//  resolution independent — no rasterization.
//

import PDFKit
import PencilKit
import UIKit

/// Markers stored in each annotation's title (`/T`) so InkPDF can
/// recognize its own annotations when a document is reopened.
enum AnnotationMarker {
    /// Visible, vector ink annotations baked from PencilKit strokes.
    static let bakedInk = "io.inkpdf.ink"
    /// Hidden annotation carrying the editable PKDrawing archive for a page.
    static let drawingArchive = "io.inkpdf.archive.drawing"
    /// Hidden annotation carrying the inserted-images archive for a page.
    static let imageArchive = "io.inkpdf.archive.images"
    /// Prefix for image stamp annotations; followed by the image UUID.
    static let imagePrefix = "io.inkpdf.image;"
    /// Text boxes created with the typing tool.
    static let textBox = "io.inkpdf.text"
}

enum InkConversion {

    /// How finely stroke splines are sampled, in canvas points.
    private static let sampleDistance: CGFloat = 1.5

    // MARK: - Strokes → PDF annotations

    /// Convert one PencilKit stroke into a vector `.ink` PDF annotation.
    ///
    /// The canvas overlay shares the page's coordinate size but uses a
    /// top-left origin, while PDF pages use bottom-left — hence the y-flip.
    static func annotation(for stroke: PKStroke, pageBounds: CGRect) -> PDFAnnotation? {
        let points = flippedPoints(for: stroke, pageBounds: pageBounds)
        guard points.count > 1 else { return nil }

        let width = lineWidth(for: stroke)
        let path = UIBezierPath()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        var bounds = path.bounds.insetBy(dx: -width, dy: -width)
        bounds = bounds.intersection(pageBounds.insetBy(dx: -width, dy: -width))
        guard !bounds.isNull, !bounds.isEmpty else { return nil }

        // Ink annotation paths are expressed relative to the annotation bounds.
        path.apply(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))

        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color(for: stroke)
        let border = PDFBorder()
        border.lineWidth = width
        annotation.border = border
        annotation.userName = AnnotationMarker.bakedInk
        annotation.add(path)
        return annotation
    }

    /// Bake every stroke of a drawing into annotations on the given page.
    /// Returns the annotations that were added.
    @discardableResult
    static func bake(drawing: PKDrawing, onto page: PDFPage) -> [PDFAnnotation] {
        let pageBounds = page.bounds(for: .cropBox)
        var added: [PDFAnnotation] = []
        for stroke in drawing.strokes {
            if let annotation = annotation(for: stroke, pageBounds: pageBounds) {
                page.addAnnotation(annotation)
                added.append(annotation)
            }
        }
        return added
    }

    // MARK: - Strokes → CGContext (flattened export)

    /// Draw a whole PKDrawing as vector paths into a PDF-space context.
    static func draw(_ drawing: PKDrawing, pageBounds: CGRect, in context: CGContext) {
        for stroke in drawing.strokes {
            let points = flippedPoints(for: stroke, pageBounds: pageBounds)
            guard points.count > 1 else { continue }
            context.saveGState()
            context.setStrokeColor(color(for: stroke).cgColor)
            context.setLineWidth(lineWidth(for: stroke))
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
            context.restoreGState()
        }
    }

    // MARK: - Stroke geometry & appearance

    private static func flippedPoints(for stroke: PKStroke, pageBounds: CGRect) -> [CGPoint] {
        var points: [CGPoint] = []
        for point in stroke.path.interpolatedPoints(by: .distance(sampleDistance)) {
            let location = point.location.applying(stroke.transform)
            points.append(CGPoint(x: pageBounds.minX + location.x,
                                  y: pageBounds.maxY - location.y))
        }
        return points
    }

    private static func lineWidth(for stroke: PKStroke) -> CGFloat {
        var total: CGFloat = 0
        var count = 0
        for point in stroke.path.interpolatedPoints(by: .distance(12)) {
            total += (point.size.width + point.size.height) / 2
            count += 1
        }
        guard count > 0 else { return 3 }
        return max(total / CGFloat(count), 0.75)
    }

    private static func color(for stroke: PKStroke) -> UIColor {
        // Resolve dynamic PencilKit colors in the light trait so ink keeps
        // the color it was drawn with, independent of system appearance.
        let base = stroke.ink.color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        switch stroke.ink.inkType {
        case .marker:
            return base.withAlphaComponent(0.55)
        case .pencil:
            return base.withAlphaComponent(0.85)
        default:
            return base
        }
    }
}
