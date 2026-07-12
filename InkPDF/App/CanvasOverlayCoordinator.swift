//
//  CanvasOverlayCoordinator.swift
//  InkPDF
//
//  Provides a PencilKit canvas as the overlay view for every PDF page
//  (PDFPageOverlayViewProvider, iOS 16+). Each page gets its own
//  PKCanvasView whose coordinate space matches the page, so PDFKit keeps
//  the canvas perfectly registered with the page while zooming/scrolling.
//

import PDFKit
import PencilKit
import UIKit

final class CanvasOverlayCoordinator: NSObject {

    /// Shared PencilKit tool picker (pens, markers, pencil, eraser, ruler, lasso).
    let toolPicker = PKToolPicker()

    /// Called whenever any page's drawing changes (used for autosave).
    var onDrawingChanged: (() -> Void)?

    /// Whether canvases accept touches (true only in Mark Up mode).
    private(set) var isInteractive = false

    /// Finger + Pencil by default; the reader can switch to Pencil-only.
    var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput {
        didSet {
            for entry in entries.values {
                entry.canvas.drawingPolicy = drawingPolicy
            }
        }
    }

    private struct Entry {
        let page: PDFPage
        let canvas: PKCanvasView
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    /// Drawings restored from the document archive (or edited earlier) for
    /// pages whose canvas has not been created yet.
    private var pendingDrawings: [ObjectIdentifier: PKDrawing] = [:]

    private var lastUsedTool: PKTool = PKInkingTool(.pen, color: .systemBlue, width: 4)

    // MARK: - Drawings

    func preloadDrawings(_ drawings: [ObjectIdentifier: PKDrawing]) {
        pendingDrawings = drawings
    }

    /// The current drawing for a page, or nil if the page has no strokes.
    func drawing(for page: PDFPage) -> PKDrawing? {
        let key = ObjectIdentifier(page)
        let drawing = entries[key]?.canvas.drawing ?? pendingDrawings[key]
        guard let drawing, !drawing.strokes.isEmpty else { return nil }
        return drawing
    }

    var hasAnyDrawing: Bool {
        entries.values.contains { !$0.canvas.drawing.strokes.isEmpty }
            || pendingDrawings.values.contains { !$0.strokes.isEmpty }
    }

    func clearDrawing(for page: PDFPage) {
        let key = ObjectIdentifier(page)
        pendingDrawings[key] = nil
        entries[key]?.canvas.drawing = PKDrawing()
        onDrawingChanged?()
    }

    // MARK: - Mode / focus

    func setInteractive(_ interactive: Bool) {
        isInteractive = interactive
        for entry in entries.values {
            entry.canvas.isUserInteractionEnabled = interactive
        }
    }

    /// Show the tool picker and give keyboard/tool focus to a page's canvas.
    func beginDrawing(on page: PDFPage?) {
        let canvas = canvasFor(page: page) ?? entries.values.first?.canvas
        guard let canvas else { return }
        toolPicker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
    }

    func endDrawing() {
        for entry in entries.values {
            toolPicker.setVisible(false, forFirstResponder: entry.canvas)
            if entry.canvas.isFirstResponder {
                entry.canvas.resignFirstResponder()
            }
        }
    }

    /// Keep the tool picker attached to the canvas of the page being viewed.
    func focusCanvas(for page: PDFPage?) {
        guard isInteractive, let canvas = canvasFor(page: page) else { return }
        if !canvas.isFirstResponder {
            toolPicker.setVisible(true, forFirstResponder: canvas)
            canvas.becomeFirstResponder()
        }
    }

    private func canvasFor(page: PDFPage?) -> PKCanvasView? {
        guard let page else { return nil }
        return entries[ObjectIdentifier(page)]?.canvas
    }
}

// MARK: - PDFPageOverlayViewProvider

extension CanvasOverlayCoordinator: PDFPageOverlayViewProvider {

    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        let key = ObjectIdentifier(page)
        if let existing = entries[key] {
            return existing.canvas
        }

        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = drawingPolicy
        canvas.delegate = self
        canvas.isScrollEnabled = false
        canvas.bounces = false
        // Keep ink colors exactly as drawn regardless of light/dark mode
        // (the page underneath is a fixed-color PDF page).
        canvas.overrideUserInterfaceStyle = .light
        canvas.isUserInteractionEnabled = isInteractive
        canvas.tool = lastUsedTool

        if let pending = pendingDrawings[key] {
            canvas.drawing = pending
        }

        toolPicker.addObserver(canvas)
        entries[key] = Entry(page: page, canvas: canvas)
        return canvas
    }
}

// MARK: - PKCanvasViewDelegate

extension CanvasOverlayCoordinator: PKCanvasViewDelegate {

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if let key = entries.first(where: { $0.value.canvas === canvasView })?.key {
            pendingDrawings[key] = canvasView.drawing
        }
        onDrawingChanged?()
    }

    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        lastUsedTool = canvasView.tool
    }
}
