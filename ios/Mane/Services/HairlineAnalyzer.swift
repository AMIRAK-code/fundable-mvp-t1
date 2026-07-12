import UIKit
import Vision

/// On-device, heuristic hairline & density analysis.
///
/// Pipeline per photo:
///  1. Normalize orientation and downscale to ≤640 px.
///  2. (Face angles) Detect the face + eyebrow line with Vision.
///  3. Sample the lower forehead as a "skin reference" color, then walk each
///     column upward from the eyebrows until the color departs from skin —
///     that transition is the hairline. The median across columns gives
///     `hairlineRatio` = forehead height ÷ face height.
///  4. Estimate density in the hair region via Otsu thresholding (dark
///     coverage) plus horizontal-gradient texture (strand edges).
///
/// These are approximations — sensitive to lighting, angle and hair color —
/// so every result carries a confidence and the UI repeats the disclaimer.
/// What matters for tracking is consistency between sessions, not absolutes.
enum HairlineAnalyzer {

    // MARK: - Public API

    static func analyze(image: UIImage, angle: ScanAngle) async -> AngleMetrics {
        guard let cgImage = downscaledCGImage(from: image, maxDimension: 640) else {
            return AngleMetrics(angle: angle, hairlineRatio: nil, densityScore: nil, confidence: 0)
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: analyzeCore(cgImage: cgImage, angle: angle))
            }
        }
    }

    // MARK: - Core

    private static func analyzeCore(cgImage: CGImage, angle: ScanAngle) -> AngleMetrics {
        guard let buffer = PixelBuffer(cgImage: cgImage) else {
            return AngleMetrics(angle: angle, hairlineRatio: nil, densityScore: nil, confidence: 0)
        }
        let width = CGFloat(buffer.width)
        let height = CGFloat(buffer.height)

        var hairlineRatio: Double?
        var confidence = 0.0
        var densityRegion: CGRect

        if angle.usesFace, let face = detectFace(in: cgImage) {
            let estimate = detectHairline(buffer: buffer, faceRect: face.rect, eyebrowY: face.eyebrowY)
            hairlineRatio = estimate?.ratio
            confidence = estimate?.confidence ?? 0.2

            if let estimate {
                // Hair band just above the detected hairline.
                let top = max(0, CGFloat(estimate.hairlineY) - face.rect.height * 0.45)
                let regionHeight = max(10, CGFloat(estimate.hairlineY) - top)
                densityRegion = CGRect(
                    x: face.rect.minX + face.rect.width * 0.15,
                    y: top,
                    width: face.rect.width * 0.7,
                    height: regionHeight
                )
            } else {
                densityRegion = CGRect(
                    x: face.rect.minX,
                    y: max(0, face.rect.minY - face.rect.height * 0.4),
                    width: face.rect.width,
                    height: face.rect.height * 0.45
                )
            }
        } else if angle == .crown {
            densityRegion = CGRect(x: 0.2 * width, y: 0.2 * height, width: 0.6 * width, height: 0.6 * height)
            confidence = 0.7
        } else {
            // No face found — density-only fallback on the upper-center region.
            densityRegion = CGRect(x: 0.25 * width, y: 0.05 * height, width: 0.5 * width, height: 0.35 * height)
            confidence = 0.2
        }

        let density = densityScore(buffer: buffer, region: densityRegion)
        return AngleMetrics(
            angle: angle,
            hairlineRatio: hairlineRatio,
            densityScore: density,
            confidence: max(0.1, min(0.95, confidence))
        )
    }

    // MARK: - Face detection

    private struct FaceGeometry {
        let rect: CGRect      // pixels, top-left origin
        let eyebrowY: CGFloat // pixels, top-left origin
    }

    private static func detectFace(in cgImage: CGImage) -> FaceGeometry? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        guard let face = request.results?.first else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        // Vision uses a lower-left origin; convert to top-left pixel space.
        let bb = face.boundingBox
        let rect = CGRect(
            x: bb.minX * width,
            y: (1 - bb.maxY) * height,
            width: bb.width * width,
            height: bb.height * height
        )
        guard rect.width > 30, rect.height > 30 else { return nil }

        var eyebrowY = rect.minY + rect.height * 0.40
        if let landmarks = face.landmarks {
            var ys: [CGFloat] = []
            for region in [landmarks.leftEyebrow, landmarks.rightEyebrow].compactMap({ $0 }) {
                let points = region.pointsInImage(imageSize: CGSize(width: width, height: height))
                ys.append(contentsOf: points.map { height - $0.y })
            }
            if let top = ys.min() {
                eyebrowY = min(max(top, rect.minY), rect.maxY)
            }
        }
        return FaceGeometry(rect: rect, eyebrowY: eyebrowY)
    }

    // MARK: - Hairline detection

    private struct HairlineEstimate {
        let ratio: Double
        let confidence: Double
        let hairlineY: Int
    }

    private static func detectHairline(buffer: PixelBuffer, faceRect: CGRect, eyebrowY: CGFloat) -> HairlineEstimate? {
        let faceHeight = faceRect.height
        guard faceHeight > 40 else { return nil }

        let x0 = max(0, Int(faceRect.minX + faceRect.width * 0.22))
        let x1 = min(buffer.width - 1, Int(faceRect.maxX - faceRect.width * 0.22))
        guard x1 > x0 + 8 else { return nil }

        let browY = min(buffer.height - 1, max(1, Int(eyebrowY)))

        // Skin reference: band on the lower forehead, just above the eyebrows.
        let skinBottom = max(0, browY - Int(faceHeight * 0.04))
        let skinTop = max(0, browY - Int(faceHeight * 0.18))
        guard skinBottom > skinTop else { return nil }
        var rSum = 0.0, gSum = 0.0, bSum = 0.0, samples = 0.0
        for y in skinTop...skinBottom {
            for x in stride(from: x0, through: x1, by: 2) {
                let c = buffer.rgb(x, y)
                rSum += c.r; gSum += c.g; bSum += c.b; samples += 1
            }
        }
        guard samples > 0 else { return nil }
        let skin = (r: rSum / samples, g: gSum / samples, b: bSum / samples)

        // Walk each column upward until the color departs from skin.
        let searchTop = max(0, browY - Int(faceHeight * 0.95))
        var hairlineYs: [Int] = []
        var columns = 0
        for x in stride(from: x0, through: x1, by: 2) {
            columns += 1
            var run = 0
            var y = skinTop
            while y > searchTop {
                let c = buffer.rgb(x, y)
                let distance = abs(c.r - skin.r) + abs(c.g - skin.g) + abs(c.b - skin.b)
                if distance > 110 {
                    run += 1
                    if run >= 4 {
                        hairlineYs.append(y + run - 1)
                        break
                    }
                } else {
                    run = 0
                }
                y -= 1
            }
        }

        let coverage = Double(hairlineYs.count) / Double(max(1, columns))
        guard coverage >= 0.35, !hairlineYs.isEmpty else { return nil }

        let sorted = hairlineYs.sorted()
        let median = sorted[sorted.count / 2]
        let foreheadHeight = Double(browY - median)
        guard foreheadHeight > 2 else { return nil }
        let ratio = min(1.2, max(0.05, foreheadHeight / Double(faceHeight)))

        // Tight agreement between columns = higher confidence.
        let q1 = sorted[sorted.count / 4]
        let q3 = sorted[(3 * sorted.count) / 4]
        let spreadPenalty = min(1.0, Double(q3 - q1) / (Double(faceHeight) * 0.25))
        let confidence = max(0.1, min(0.95, coverage * (1.0 - 0.6 * spreadPenalty)))

        return HairlineEstimate(ratio: ratio, confidence: confidence, hairlineY: median)
    }

    // MARK: - Density estimation

    private static func densityScore(buffer: PixelBuffer, region: CGRect) -> Double {
        let x0 = max(0, Int(region.minX))
        let x1 = min(buffer.width - 1, Int(region.maxX))
        let y0 = max(0, Int(region.minY))
        let y1 = min(buffer.height - 1, Int(region.maxY))
        guard x1 > x0 + 4, y1 > y0 + 4 else { return 0 }

        var histogram = [Int](repeating: 0, count: 256)
        var total = 0
        for y in y0...y1 {
            for x in x0...x1 {
                histogram[min(255, Int(buffer.luminance(x, y)))] += 1
                total += 1
            }
        }

        let (threshold, separation) = otsu(histogram: histogram, total: total)

        var darkCount = 0
        var edgeCount = 0
        var edgeSamples = 0
        var luminanceSum = 0.0
        for y in y0...y1 {
            for x in x0...x1 {
                let lum = buffer.luminance(x, y)
                luminanceSum += lum
                if lum < threshold { darkCount += 1 }
                if x < x1 {
                    if abs(lum - buffer.luminance(x + 1, y)) > 24 { edgeCount += 1 }
                    edgeSamples += 1
                }
            }
        }

        let pixelCount = Double(total)
        let meanLuminance = luminanceSum / pixelCount
        var coverage = Double(darkCount) / pixelCount
        // Nearly uniform region: Otsu's split is arbitrary, so classify the
        // whole region as hair (dark) or scalp (bright) by mean luminance.
        if separation < 0.35 {
            coverage = meanLuminance < 110 ? 0.9 : 0.15
        }
        let edgeFraction = Double(edgeCount) / Double(max(1, edgeSamples))
        let score = 100.0 * min(1.0, 0.7 * coverage + 0.6 * min(1.0, edgeFraction * 3.0))
        return max(0, min(100, score))
    }

    /// Otsu's threshold plus the normalized between-class variance (0–1),
    /// which indicates how bimodal (hair vs scalp) the region really is.
    private static func otsu(histogram: [Int], total: Int) -> (threshold: Double, separation: Double) {
        guard total > 0 else { return (128, 0) }
        let n = Double(total)
        var sumAll = 0.0
        for i in 0..<256 { sumAll += Double(i) * Double(histogram[i]) }
        let meanAll = sumAll / n
        var totalVariance = 0.0
        for i in 0..<256 {
            let d = Double(i) - meanAll
            totalVariance += d * d * Double(histogram[i])
        }
        totalVariance /= n

        var weightBackground = 0.0
        var sumBackground = 0.0
        var bestThreshold = 128.0
        var bestBetween = 0.0
        for t in 0..<256 {
            weightBackground += Double(histogram[t])
            if weightBackground == 0 { continue }
            let weightForeground = n - weightBackground
            if weightForeground == 0 { break }
            sumBackground += Double(t) * Double(histogram[t])
            let meanBackground = sumBackground / weightBackground
            let meanForeground = (sumAll - sumBackground) / weightForeground
            let diff = meanBackground - meanForeground
            let between = (weightBackground / n) * (weightForeground / n) * diff * diff
            if between > bestBetween {
                bestBetween = between
                bestThreshold = Double(t)
            }
        }
        let separation = totalVariance > 0 ? bestBetween / totalVariance : 0
        return (bestThreshold, separation)
    }

    // MARK: - Image helpers

    private static func downscaledCGImage(from image: UIImage, maxDimension: CGFloat) -> CGImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: max(1, floor(size.width * scale)), height: max(1, floor(size.height * scale)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.cgImage
    }
}

// MARK: - Pixel buffer

/// RGBA8 snapshot of a CGImage with top-left origin pixel access.
private struct PixelBuffer {
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let data: [UInt8]

    init?(cgImage: CGImage) {
        let w = cgImage.width
        let h = cgImage.height
        guard w > 0, h > 0 else { return nil }
        let rowBytes = w * 4
        var pixels = [UInt8](repeating: 0, count: rowBytes * h)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let drawn = pixels.withUnsafeMutableBytes { ptr -> Bool in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: rowBytes,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        width = w
        height = h
        bytesPerRow = rowBytes
        data = pixels
    }

    func rgb(_ x: Int, _ y: Int) -> (r: Double, g: Double, b: Double) {
        let i = y * bytesPerRow + x * 4
        return (Double(data[i]), Double(data[i + 1]), Double(data[i + 2]))
    }

    func luminance(_ x: Int, _ y: Int) -> Double {
        let c = rgb(x, y)
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }
}
