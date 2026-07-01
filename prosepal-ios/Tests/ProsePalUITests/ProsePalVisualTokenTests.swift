import Foundation
import Testing
@testable import ProsePalUI

@Test
func prosePalRadiusTokensMirrorDesignSystem() throws {
    let radiusCSS = try String(
        contentsOf: designSystemRoot.appending(path: "tokens/radius.css"),
        encoding: .utf8
    )

    #expect(radiusCSS.contains("--radius-xs:    6px;"))
    #expect(radiusCSS.contains("--radius-sm:    10px;"))
    #expect(radiusCSS.contains("--radius-md:    14px;"))
    #expect(radiusCSS.contains("--radius-lg:    18px;"))
    #expect(radiusCSS.contains("--radius-xl:    22px;"))
    #expect(radiusCSS.contains("--radius-2xl:   28px;"))
    #expect(radiusCSS.contains("--radius-3xl:   36px;"))
    #expect(radiusCSS.contains("--radius-canvas:  20px;"))

    #expect(ProsePalRadius.xs == 6)
    #expect(ProsePalRadius.small == 10)
    #expect(ProsePalRadius.medium == 14)
    #expect(ProsePalRadius.large == 18)
    #expect(ProsePalRadius.card == 22)
    #expect(ProsePalRadius.sheet == 28)
    #expect(ProsePalRadius.threeExtraLarge == 36)
    #expect(ProsePalRadius.canvas == 20)
}

@Test
func prosePalCanonicalKitKeepsProductionThemeTokens() throws {
    let kitHTML = try String(
        contentsOf: designSystemRoot.appending(path: "ui_kits/prosepal/index.html"),
        encoding: .utf8
    )

    #expect(kitHTML.contains("--bg: oklch(0.957 0.018 80);"))
    #expect(kitHTML.contains("--surface: oklch(0.985 0.012 82);"))
    #expect(kitHTML.contains("--accent: oklch(0.520 0.110 40);"))
    #expect(kitHTML.contains("--glass-fill:        oklch(0.987 0.016 80 / 0.60);"))
    #expect(kitHTML.contains("--glass-shadow:"))
    #expect(kitHTML.contains("--canvas-font: var(--font-reading);"))
}

private var designSystemRoot: URL {
    packageRoot
        .deletingLastPathComponent()
        .appending(path: "design-system")
}

private var packageRoot: URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}
