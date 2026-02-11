import AppKit

enum MenuBarRenderer {

    private static let iconWidth: CGFloat = 80

    static func createImage(sessionPercent: Double, weeklyPercent: Double,
                            isPacingWarning: Bool) -> NSImage {
        let height: CGFloat = 16

        let flameImg: NSImage? = isPacingWarning ? createFlameImage() : nil
        let flameSpace: CGFloat = flameImg.map { $0.size.width + 2 } ?? 0
        let totalWidth = iconWidth + flameSpace

        let image = NSImage(size: NSSize(width: totalWidth, height: height))
        image.lockFocus()

        drawDualBar(session: sessionPercent, weekly: weeklyPercent, width: iconWidth, height: height)

        if let flame = flameImg {
            let y = (height - flame.size.height) / 2
            flame.draw(at: NSPoint(x: iconWidth + 2, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    static func titleText(sessionPercent: Double, weeklyPercent: Double, displayMode: Int) -> String {
        switch displayMode {
        case 1:  return " \(pct(sessionPercent)) \u{00B7} \(pct(weeklyPercent))"
        case 2:  return " \(pct(sessionPercent))/\(pct(weeklyPercent))"
        default: return ""
        }
    }

    static func tooltip(sessionPercent: Double, sessionReset: String,
                        weeklyPercent: Double, weeklyReset: String) -> String {
        var lines: [String] = []
        lines.append("5-hour session: \(pct(sessionPercent)) used")
        if !sessionReset.isEmpty { lines.append(sessionReset) }
        lines.append("7-day weekly: \(pct(weeklyPercent)) used")
        if !weeklyReset.isEmpty { lines.append(weeklyReset) }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func pct(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }

    private static func gaugeColor(for percent: Double) -> NSColor {
        if percent >= 0.9 { return .systemRed }
        if percent >= 0.7 { return .systemOrange }
        return .systemGreen
    }

    private static func barColor(for percent: Double) -> NSColor {
        if percent >= 0.9 { return .systemRed }
        if percent >= 0.7 { return .systemOrange }
        return .systemBlue
    }

    // MARK: - Flame

    private static func createFlameImage() -> NSImage? {
        let sizeConfig = NSImage.SymbolConfiguration(pointSize: 9, weight: .medium)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [.systemOrange])
        let config = sizeConfig.applying(colorConfig)

        if let symbol = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            return symbol
        }
        let size = NSSize(width: 6, height: 8)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        img.unlockFocus()
        return img
    }

    // MARK: - Dual Bar

    private static func drawDualBar(session: Double, weekly: Double, width: CGFloat, height: CGFloat) {
        let dotSize: CGFloat = 7
        let dotGap: CGFloat = 4
        let barWidth = width - dotSize - dotGap
        let barHeight: CGFloat = 5
        let gap: CGFloat = 2
        let topY = (height + gap) / 2
        let botY = (height - gap) / 2 - barHeight
        let barX = dotSize + dotGap

        // Status dot
        let worst = max(session, weekly)
        let dotY = (height - dotSize) / 2
        let dotPath = NSBezierPath(ovalIn: NSRect(x: 0, y: dotY, width: dotSize, height: dotSize))
        gaugeColor(for: worst).setFill()
        dotPath.fill()

        // Bars
        drawPillBar(in: NSRect(x: barX, y: topY, width: barWidth, height: barHeight), percent: session)
        drawPillBar(in: NSRect(x: barX, y: botY, width: barWidth, height: barHeight), percent: weekly)
    }

    private static func drawPillBar(in rect: NSRect, percent: Double) {
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        NSColor.tertiaryLabelColor.withAlphaComponent(0.25).setFill()
        bgPath.fill()

        let inset: CGFloat = 0.5
        let maxW = rect.width - inset * 2
        let fillW = max(0, min(maxW, maxW * CGFloat(percent)))
        if fillW > 0 {
            let fillRect = NSRect(x: rect.minX + inset, y: rect.minY + inset,
                                  width: fillW, height: rect.height - inset * 2)
            let fillPath = NSBezierPath(roundedRect: fillRect,
                                        xRadius: fillRect.height / 2, yRadius: fillRect.height / 2)
            barColor(for: percent).setFill()
            fillPath.fill()
        }
    }
}
