//
//  ImageStampAnnotation.swift
//  InkPDF
//
//  A stamp annotation that renders an inserted picture on the page.
//  The raw image bytes travel with the annotation so they can be
//  archived into the PDF (see DrawingArchive) and restored on reopen.
//

import PDFKit
import UIKit

final class ImageStampAnnotation: PDFAnnotation {

    let imageData: Data
    let imageID: String
    private let cgImage: CGImage?

    init(bounds: CGRect, imageData: Data, imageID: String = UUID().uuidString) {
        self.imageData = imageData
        self.imageID = imageID
        self.cgImage = UIImage(data: imageData)?.cgImage
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        self.userName = AnnotationMarker.imagePrefix + imageID
        self.shouldPrint = true
    }

    required init?(coder: NSCoder) {
        fatalError("ImageStampAnnotation does not support NSCoding")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage else { return }
        context.saveGState()
        // The context uses PDF page coordinates (origin bottom-left),
        // which is exactly what CGContext.draw(_:in:) expects.
        context.interpolationQuality = .high
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}
