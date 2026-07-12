//
//  InkPDFApp.swift
//  InkPDF
//
//  App entry point. The library (document grid) is the root screen;
//  the reader is presented full screen on top of it.
//

import SwiftUI

@main
struct InkPDFApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(model)
                .onOpenURL { url in
                    model.handle(url: url)
                }
        }
    }
}
