import ProsePalDomain
import SwiftUI

extension Binding where Value == String {
    func prosePalLimited(to limit: Int) -> Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = ProsePalTextInput.limited($0, to: limit) }
        )
    }
}

struct MomentCharacterLimitStatus: View {
    let text: String
    let limit: Int

    var body: some View {
        if text.count >= warningThreshold {
            Text("\(text.count) of \(limit) characters")
                .font(.caption2)
                .foregroundStyle(text.count == limit ? Color.orange : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("\(text.count) of \(limit) characters used")
        }
    }

    private var warningThreshold: Int {
        max(1, limit - min(100, limit / 5))
    }
}
