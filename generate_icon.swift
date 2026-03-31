import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Create app icon for ScrollCapture
// macOS app icon sizes: 16, 32, 64, 128, 256, 512, 1024

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]

func createIcon(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // Background gradient colors
    let gradientColors: [CGColor] = [
        CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),  // Blue
        CGColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0),  // Purple
    ]

    // Draw rounded rectangle background (macOS style)
    let cornerRadius = CGFloat(size) * 0.22
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    let path = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    context.addPath(path)
    context.clip()

    // Draw gradient background
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: [0.0, 1.0]) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: CGFloat(size), y: CGFloat(size)),
            options: []
        )
    }

    // Draw camera/scroll icon
    let lineWidth = CGFloat(size) * 0.06

    // Main rectangle (representing screenshot area)
    let rectMargin = CGFloat(size) * 0.2
    let rectWidth = CGFloat(size) * 0.6
    let rectHeight = CGFloat(size) * 0.45
    let mainRect = CGRect(
        x: rectMargin,
        y: CGFloat(size) * 0.25,
        width: rectWidth,
        height: rectHeight
    )

    // Draw stacked rectangles (scroll effect)
    for i in 0..<3 {
        let offset = CGFloat(i) * CGFloat(size) * 0.08
        let alpha = 1.0 - CGFloat(i) * 0.25

        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alpha))
        context.setLineWidth(lineWidth)

        let yOffset = CGFloat(size) * 0.15 + offset
        let currentRect = CGRect(
            x: rectMargin + offset * 0.3,
            y: yOffset,
            width: rectWidth - offset * 0.3,
            height: rectHeight
        )

        let rectPath = CGPath(
            roundedRect: currentRect,
            cornerWidth: CGFloat(size) * 0.05,
            cornerHeight: CGFloat(size) * 0.05,
            transform: nil
        )
        context.addPath(rectPath)
        context.strokePath()
    }

    // Draw camera lens circle
    let lensRadius = CGFloat(size) * 0.12
    let lensCenter = CGPoint(
        x: CGFloat(size) * 0.5,
        y: CGFloat(size) * 0.65
    )

    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9))
    context.addEllipse(in: CGRect(
        x: lensCenter.x - lensRadius,
        y: lensCenter.y - lensRadius,
        width: lensRadius * 2,
        height: lensRadius * 2
    ))
    context.fillPath()

    // Inner lens
    let innerRadius = lensRadius * 0.6
    context.setFillColor(CGColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1.0))
    context.addEllipse(in: CGRect(
        x: lensCenter.x - innerRadius,
        y: lensCenter.y - innerRadius,
        width: innerRadius * 2,
        height: innerRadius * 2
    ))
    context.fillPath()

    // Highlight
    let highlightRadius = lensRadius * 0.25
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8))
    context.addEllipse(in: CGRect(
        x: lensCenter.x - highlightRadius - lensRadius * 0.3,
        y: lensCenter.y - highlightRadius - lensRadius * 0.3,
        width: highlightRadius * 2,
        height: highlightRadius * 2
    ))
    context.fillPath()

    return context.makeImage()
}

// Create output directory
let outputDir = "ScrollCapture/Resources/Assets.xcassets/AppIcon.appiconset"
let fileManager = FileManager.default

if !fileManager.fileExists(atPath: outputDir) {
    try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
}

// Generate icons
var contents: [String: Any] = [
    "images": [],
    "info": ["version": 1, "author": "xcode"]
]

var images: [[String: Any]] = []

for size in sizes {
    guard let image = createIcon(size: size) else { continue }

    let filename: String
    if size == 1024 {
        filename = "icon_1024.png"
    } else {
        filename = "icon_\(size).png"
    }

    let url = URL(fileURLWithPath: "\(outputDir)/\(filename)")

    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    CGImageDestinationAddImage(destination!, image, nil)
    CGImageDestinationFinalize(destination!)

    print("Generated: \(filename)")

    // Add to Contents.json
    if size == 1024 {
        images.append([
            "idiom": "mac",
            "scale": "1x",
            "size": "1024x1024",
            "filename": filename
        ])
    } else {
        let scale = size >= 256 ? 2 : 1
        let baseSize = scale == 2 ? size / 2 : size
        images.append([
            "idiom": "mac",
            "scale": "\(scale)x",
            "size": "\(baseSize)x\(baseSize)",
            "filename": filename
        ])
    }
}

contents["images"] = images

// Write Contents.json
let contentsURL = URL(fileURLWithPath: "\(outputDir)/Contents.json")
let jsonData = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
try jsonData.write(to: contentsURL)

print("\n✅ App icon generated successfully!")
print("Location: \(outputDir)")