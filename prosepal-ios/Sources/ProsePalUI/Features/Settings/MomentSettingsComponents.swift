import SwiftUI

struct MomentSettingsStaticRowDescriptor: Identifiable, Equatable, Sendable {
    enum ID: String, Sendable {
        case toneOptions
        case voiceProfile
        case textSize
        case privateDraftPrivacy
        case privateDraftReadiness
        case takeMoreCare
        case version
        case direction
    }

    let id: ID
    let systemImage: String
    let title: String
    let subtitle: String?
    let trailing: String?

    static func writing(isRelationshipVaultPersistent: Bool) -> [Self] {
        [
            Self(
                id: .toneOptions,
                systemImage: "paintbrush",
                title: String(localized: "Tone options"),
                subtitle: String(localized: "Choose a tone for each moment"),
                trailing: String(localized: "Per draft")
            ),
            Self(
                id: .voiceProfile,
                systemImage: "person.crop.square",
                title: String(localized: "Voice profile"),
                subtitle: String(localized: "Relationship memory stays on this device"),
                trailing: isRelationshipVaultPersistent
                    ? String(localized: "Available")
                    : String(localized: "Temporary")
            ),
            Self(
                id: .textSize,
                systemImage: "textformat.size",
                title: String(localized: "Text size"),
                subtitle: String(localized: "Follows your device setting"),
                trailing: String(localized: "System")
            ),
        ]
    }

    static func privateDraftPrivacy(isConfigured: Bool) -> Self {
        Self(
            id: .privateDraftPrivacy,
            systemImage: "lock",
            title: String(localized: "Private Draft"),
            subtitle: String(localized: "Uses on-device writing when available"),
            trailing: isConfigured
                ? String(localized: "Automatic")
                : String(localized: "Unavailable")
        )
    }

    static func privateDraftReadiness(isConfigured: Bool) -> Self {
        Self(
            id: .privateDraftReadiness,
            systemImage: "lock.doc",
            title: String(localized: "Private Draft"),
            subtitle: nil,
            trailing: isConfigured
                ? String(localized: "Device dependent")
                : String(localized: "Unavailable here")
        )
    }

    static func takeMoreCare(isConfigured: Bool) -> Self {
        Self(
            id: .takeMoreCare,
            systemImage: "heart.text.square",
            title: String(localized: "Take more care"),
            subtitle: nil,
            trailing: isConfigured
                ? String(localized: "Ready")
                : String(localized: "Needs setup")
        )
    }

    static func version(_ value: String) -> Self {
        Self(
            id: .version,
            systemImage: "info.circle",
            title: String(localized: "Version"),
            subtitle: nil,
            trailing: value
        )
    }

    static let direction = Self(
        id: .direction,
        systemImage: "iphone",
        title: String(localized: "Direction"),
        subtitle: nil,
        trailing: String(localized: "Native iOS")
    )
}

struct MomentSettingsStatusWash: View {
    var body: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color.prosePalPaper, location: 0.0),
                Gradient.Stop(color: Color.prosePalPaper, location: 0.78),
                Gradient.Stop(color: Color.prosePalPaper.opacity(0.0), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 106)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MomentSettingsProfileCard: View {
    let initials: String
    let title: String
    let detail: String
    let isPremium: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(initials)
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 58, height: 58)
                .background(Color.prosePalCoral.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Text(isPremium ? String(localized: "Pro") : String(localized: "Free"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.prosePalCoralDeep)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(Color.prosePalCoral.opacity(0.12), in: Capsule(style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Color.prosePalPaper.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
    }
}

struct MomentSettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
        }
    }
}

struct MomentSettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }
}

struct MomentSettingsStaticRows: View {
    let rows: [MomentSettingsStaticRowDescriptor]

    var body: some View {
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
            if index > 0 {
                MomentSettingsDivider()
            }
            MomentSettingsRowContent(row: row)
        }
    }
}

struct MomentSettingsRowContent: View {
    let systemImage: String
    let title: String
    let subtitle: String?
    let trailing: String?
    let showsChevron: Bool
    let isDestructive: Bool

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        trailing: String? = nil,
        showsChevron: Bool = false,
        isDestructive: Bool = false
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.showsChevron = showsChevron
        self.isDestructive = isDestructive
    }

    init(row: MomentSettingsStaticRowDescriptor) {
        self.init(
            systemImage: row.systemImage,
            title: row.title,
            subtitle: row.subtitle,
            trailing: row.trailing
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(isDestructive ? Color.red.opacity(0.78) : Color.prosePalSlate)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.84) : Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailing {
                Text(trailing)
                    .font(.body)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
