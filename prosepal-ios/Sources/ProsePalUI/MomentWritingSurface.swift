import SwiftUI

struct MomentWritingPageSurface<Content: View, Footer: View>: View {
    let prompt: String
    let isCareful: Bool
    let showsRules: Bool
    let showsFooter: Bool
    let minHeight: CGFloat

    private let content: Content
    private let footer: Footer

    init(
        prompt: String,
        isCareful: Bool = false,
        showsRules: Bool = true,
        showsFooter: Bool = true,
        minHeight: CGFloat = 104,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.prompt = prompt
        self.isCareful = isCareful
        self.showsRules = showsRules
        self.showsFooter = showsFooter
        self.minHeight = minHeight
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(accentColor)

            content
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
                .background(alignment: .topLeading) {
                    if showsRules {
                        MomentRuledPaperLines()
                            .accessibilityHidden(true)
                    }
                }

            if showsFooter {
                Divider()
                    .overlay(Color.prosePalCoral.opacity(0.14))

                footer
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.prosePalPaper)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 0.8)
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(accentColor.opacity(isCareful ? 0.24 : 0.18))
                        .frame(width: 3)
                        .padding(.vertical, 18)
                }
                .shadow(color: Color.prosePalCoralDeep.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }
}

private struct MomentRuledPaperLines: View {
    var lineHeight: CGFloat = 34

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y = lineHeight - 1

            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += lineHeight
            }

            context.stroke(
                path,
                with: .color(Color.prosePalCoral.opacity(0.09)),
                lineWidth: 0.6
            )
        }
    }
}
