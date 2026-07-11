import SwiftUI

// MARK: - Liquid Glass

/// On iOS 26+ (built with Xcode 26 / Swift 6.2) cards get the real Liquid
/// Glass treatment. On older SDKs or older systems they fall back to a
/// frosted material that reads the same way. The `#if compiler` guard keeps
/// the project building on Xcode 16 as well, where `glassEffect` doesn't
/// exist in the SDK.
extension View {
    @ViewBuilder
    func liquidGlassCard(cornerRadius: CGFloat = 26) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            frostedFallback(cornerRadius: cornerRadius)
        }
        #else
        frostedFallback(cornerRadius: cornerRadius)
        #endif
    }

    @ViewBuilder
    fileprivate func frostedFallback(cornerRadius: CGFloat) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 6)
        )
    }
}

/// A padded, full-width glass container — the basic building block of every
/// screen in the app.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: cornerRadius)
    }
}

// MARK: - Background

/// A soft gradient with large blurred color fields behind it. Deliberately
/// low-contrast and low-saturation — and it gives the glass layers something
/// gentle to refract.
struct CalmBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CalmPalette.backgroundTop, CalmPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(CalmPalette.sage.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -120, y: -220)
            Circle()
                .fill(CalmPalette.mist.opacity(0.15))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 150, y: 60)
            Circle()
                .fill(CalmPalette.lavender.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -40, y: 380)
        }
        .ignoresSafeArea()
    }
}
