//
//  NotebookFactory.swift
//  InkPDF
//
//  Generates PDF documents in code: the welcome/tutorial document and
//  fresh notebooks with blank, lined, grid, or dotted paper.
//

import UIKit

enum PaperStyle: String, CaseIterable, Identifiable {
    case blank
    case lined
    case grid
    case dotted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blank: return "Blank"
        case .lined: return "Lined"
        case .grid: return "Grid"
        case .dotted: return "Dotted"
        }
    }

    var symbolName: String {
        switch self {
        case .blank: return "doc"
        case .lined: return "doc.text"
        case .grid: return "squareshape.split.3x3"
        case .dotted: return "circle.grid.3x3"
        }
    }
}

enum NotebookPageSize: String, CaseIterable, Identifiable {
    case a4
    case usLetter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .a4: return "A4"
        case .usLetter: return "US Letter"
        }
    }

    /// Size in PDF points (1/72 inch).
    var size: CGSize {
        switch self {
        case .a4: return CGSize(width: 595.2, height: 841.8)
        case .usLetter: return CGSize(width: 612, height: 792)
        }
    }
}

enum NotebookFactory {

    // MARK: - Notebooks

    static func notebookData(style: PaperStyle, pageSize: CGSize, pageCount: Int) -> Data {
        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            for _ in 0..<max(pageCount, 1) {
                context.beginPage()
                drawPaper(style: style, in: bounds, context: context.cgContext)
            }
        }
    }

    static func drawPaper(style: PaperStyle, in bounds: CGRect, context: CGContext) {
        let ruleColor = UIColor(white: 0.78, alpha: 1)
        let margin: CGFloat = 40

        context.saveGState()
        defer { context.restoreGState() }

        switch style {
        case .blank:
            break

        case .lined:
            let spacing: CGFloat = 28
            context.setStrokeColor(ruleColor.cgColor)
            context.setLineWidth(0.7)
            var y = margin + spacing
            while y < bounds.height - margin {
                context.move(to: CGPoint(x: margin, y: y))
                context.addLine(to: CGPoint(x: bounds.width - margin, y: y))
                y += spacing
            }
            context.strokePath()
            // Red margin rule, like a classic notepad.
            context.setStrokeColor(UIColor.systemRed.withAlphaComponent(0.35).cgColor)
            context.move(to: CGPoint(x: margin + 24, y: margin))
            context.addLine(to: CGPoint(x: margin + 24, y: bounds.height - margin))
            context.strokePath()

        case .grid:
            let spacing: CGFloat = 24
            context.setStrokeColor(ruleColor.withAlphaComponent(0.8).cgColor)
            context.setLineWidth(0.5)
            var x = margin
            while x <= bounds.width - margin {
                context.move(to: CGPoint(x: x, y: margin))
                context.addLine(to: CGPoint(x: x, y: bounds.height - margin))
                x += spacing
            }
            var y = margin
            while y <= bounds.height - margin {
                context.move(to: CGPoint(x: margin, y: y))
                context.addLine(to: CGPoint(x: bounds.width - margin, y: y))
                y += spacing
            }
            context.strokePath()

        case .dotted:
            let spacing: CGFloat = 24
            context.setFillColor(ruleColor.cgColor)
            var y = margin
            while y <= bounds.height - margin {
                var x = margin
                while x <= bounds.width - margin {
                    context.fillEllipse(in: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2))
                    x += spacing
                }
                y += spacing
            }
        }
    }

    // MARK: - Welcome document

    static func welcomeData() -> Data {
        let bounds = CGRect(origin: .zero, size: NotebookPageSize.a4.size)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            context.beginPage()
            drawWelcomePage(in: bounds)
            context.beginPage()
            drawPaper(style: .lined, in: bounds, context: context.cgContext)
            context.beginPage()
            drawPaper(style: .dotted, in: bounds, context: context.cgContext)
        }
    }

    private static func drawWelcomePage(in bounds: CGRect) {
        let margin: CGFloat = 56
        var y: CGFloat = 96

        let titleStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 44, weight: .bold),
            .foregroundColor: UIColor(red: 0.32, green: 0.28, blue: 0.90, alpha: 1)
        ]
        let subtitleStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        let headingStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let bodyStyle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor(white: 0.25, alpha: 1)
        ]

        func draw(_ text: String, style: [NSAttributedString.Key: Any], spacing: CGFloat) {
            let rect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: .greatestFiniteMagnitude)
            let bounding = (text as NSString).boundingRect(with: rect.size,
                                                           options: [.usesLineFragmentOrigin],
                                                           attributes: style,
                                                           context: nil)
            (text as NSString).draw(in: CGRect(x: rect.minX, y: rect.minY,
                                               width: rect.width, height: ceil(bounding.height)),
                                    withAttributes: style)
            y += ceil(bounding.height) + spacing
        }

        draw("Welcome to InkPDF", style: titleStyle, spacing: 8)
        draw("Read, study, and mark up PDFs — with vector ink, text, and images.", style: subtitleStyle, spacing: 28)

        let sections: [(String, String)] = [
            ("✏️  Mark Up",
             "Tap “Mark Up” in the bottom bar to draw with your finger or Apple Pencil. The tool picker gives you pens, markers, pencils, an eraser, a ruler, and a lasso — every stroke is stored as vector ink, so it stays sharp at any zoom level."),
            ("🖍  Highlight text",
             "In Read mode, select any text, then tap the highlighter button to highlight, underline, or strike it through. Pick your color with the color well."),
            ("🔤  Type notes",
             "Switch to Edit mode and tap anywhere to add a text box. Tap an existing note to edit it, drag it to move it, and long-press to delete it."),
            ("🖼  Insert pictures",
             "Tap the photo button to place an image from your library onto the page. Drag to reposition, pinch to resize."),
            ("📄  Pages & notebooks",
             "Create blank, lined, grid, or dotted notebooks from the library, and append pages to any document from the ••• menu — great for taking notes next to a paper you are reading."),
            ("🧩  Widgets",
             "Add the InkPDF widget to your Home Screen or Lock Screen to jump straight back into your recent documents."),
            ("💾  Saving & sharing",
             "Everything autosaves into the PDF itself. Use the share button to export a flattened copy that looks identical in any PDF viewer.")
        ]

        for (heading, body) in sections {
            draw(heading, style: headingStyle, spacing: 6)
            draw(body, style: bodyStyle, spacing: 18)
        }

        draw("Try it right now — the next two pages are lined and dotted paper. Happy studying! ✍️",
             style: subtitleStyle, spacing: 0)
    }
}
