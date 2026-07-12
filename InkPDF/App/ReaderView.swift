//
//  ReaderView.swift
//  InkPDF
//
//  SwiftUI wrapper that hosts the UIKit-based PDF reader full screen.
//

import SwiftUI
import UIKit

struct ReaderContainer: UIViewControllerRepresentable {
    let url: URL
    let onClose: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let reader = PDFReaderViewController(fileURL: url)
        reader.onClose = onClose
        let navigation = UINavigationController(rootViewController: reader)
        navigation.navigationBar.prefersLargeTitles = false
        return navigation
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // The reader manages its own state.
    }
}
