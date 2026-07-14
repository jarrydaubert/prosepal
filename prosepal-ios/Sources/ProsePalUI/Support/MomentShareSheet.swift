import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MomentShareRequest: Identifiable {
    let id = UUID()
    let activityItems: [Any]

    static func text(_ text: String) -> MomentShareRequest {
        MomentShareRequest(activityItems: [text])
    }
}

extension View {
    @ViewBuilder
    func momentShareSheet(_ request: Binding<MomentShareRequest?>) -> some View {
        #if canImport(UIKit)
        sheet(isPresented: Binding(
            get: { request.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    request.wrappedValue = nil
                }
            }
        )) {
            if let request = request.wrappedValue {
                MomentActivityView(activityItems: request.activityItems)
            }
        }
        #else
        self
        #endif
    }
}

#if canImport(UIKit)
private struct MomentActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
#endif
