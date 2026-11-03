import SwiftUI

struct MomentDetailHero: View {
    let systemImage: String
    let title: String
    let detail: String
    var accent: Color = .prosePalCoralDeep

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(accent)
                .frame(width: 52, height: 52)
                .background(
                    accent.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MomentDetailCard<Content: View>: View {
    let title: String
    let systemImage: String
    let footer: String?
    private let content: Content

    init(
        title: String,
        systemImage: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 26, height: 26)
                    .background(
                        Color.prosePalCoral.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
            }

            content

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .lineSpacing(2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.prosePalPaper.opacity(0.94),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}
