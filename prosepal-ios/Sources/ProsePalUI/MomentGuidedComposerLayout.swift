import SwiftUI

struct MomentComposerStepDefinition: Equatable {
    let number: Int
    let title: String
    let detail: String

    static let person = Self(number: 1, title: "Who", detail: "Name the person.")
    static let occasion = Self(number: 2, title: "What's the occasion?", detail: "Pick the moment.")
    static let tone = Self(number: 3, title: "Tone", detail: "Choose how it should feel.")
    static let generate = Self(number: 5, title: "Generate", detail: "Create the draft.")

    static func length(detail: String) -> Self {
        Self(number: 4, title: "Length", detail: detail)
    }
}

struct MomentGuidedComposerLayout: View {
    let isCareful: Bool
    let intro: AnyView
    let rows: [AnyView]

    init<Intro: View>(
        isCareful: Bool,
        @ViewBuilder intro: () -> Intro,
        rows: [AnyView]
    ) {
        self.isCareful = isCareful
        self.intro = AnyView(intro())
        self.rows = rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            intro

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows.indices, id: \.self) { index in
                    rows[index]

                    if index < rows.count - 1 {
                        divider
                    }
                }
            }
        }
        .padding(14)
        .background {
            MomentCardBackground(
                isCareful: isCareful,
                prominence: .standard
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 38)
            .accessibilityHidden(true)
    }
}

struct MomentComposerStep: View {
    let definition: MomentComposerStepDefinition
    let accentColor: Color
    let content: AnyView

    init<Content: View>(
        definition: MomentComposerStepDefinition,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.definition = definition
        self.accentColor = accentColor
        self.content = AnyView(content())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(definition.number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(accentColor, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(definition.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text(definition.detail)
                        .font(.caption)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Guided composer layout") {
    ScrollView {
        MomentGuidedComposerLayout(
            isCareful: false,
            intro: {
                Text("Write a message")
                    .font(.headline)
            },
            rows: [
                AnyView(MomentComposerStep(
                    definition: .person,
                    accentColor: .prosePalCoral
                ) {
                    TextField("Name or person", text: .constant("Alex"))
                        .textFieldStyle(.roundedBorder)
                }),
                AnyView(MomentComposerStep(
                    definition: .occasion,
                    accentColor: .prosePalCoral
                ) {
                    Text("Birthday")
                }),
                AnyView(Text("Optional detail"))
            ]
        )
        .padding()
    }
    .background(Color.prosePalPaper)
}
