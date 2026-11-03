import SwiftUI
import Testing
@testable import ProsePalUI

@MainActor
@Test
func guidedComposerLayoutMaterializesMixedRowsBehindStableTypeBoundaries() {
    let rows: [AnyView] = [
        AnyView(MomentComposerStep(
            definition: .person,
            accentColor: .prosePalCoral
        ) {
            TextField("Name", text: .constant("Alex"))
                .textFieldStyle(.roundedBorder)
        }),
        AnyView(MomentComposerStep(
            definition: .occasion,
            accentColor: .prosePalCoral
        ) {
            Button("Birthday") {}
        }),
        AnyView(MomentComposerStep(
            definition: .tone,
            accentColor: .prosePalCoral
        ) {
            Menu("Heartfelt") {
                Button("Warm") {}
            }
        }),
        AnyView(MomentComposerStep(
            definition: .length(detail: "A few lines."),
            accentColor: .prosePalCoral
        ) {
            HStack {
                Text("Brief")
                Text("Standard")
            }
        }),
        AnyView(MomentComposerStep(
            definition: .generate,
            accentColor: .prosePalCoral
        ) {
            Label("Generate", systemImage: "sparkles")
        }),
        AnyView(Button("Relationship") {}),
        AnyView(TextField("Optional detail", text: .constant("A quiet cup of tea")))
    ]
    let layout = MomentGuidedComposerLayout(
        isCareful: false,
        intro: { Text("Write a message") },
        rows: rows
    )
    let renderer = ImageRenderer(content: layout.frame(width: 390))

    #expect(renderer.cgImage != nil)
}

@Test
func guidedComposerStepDefinitionsDescribeTheVisibleFlow() {
    let steps = [
        MomentComposerStepDefinition.person,
        .occasion,
        .tone,
        .length(detail: "A few lines."),
        .generate,
    ]

    #expect(steps.map(\.number) == [1, 2, 3, 4, 5])
    #expect(steps.map(\.title) == ["Who", "What's the occasion?", "Tone", "Length", "Generate"])
    #expect(steps.map(\.detail) == [
        "Name the person.",
        "Pick the moment.",
        "Choose how it should feel.",
        "A few lines.",
        "Create the draft.",
    ])
}
