import ProsePalAPI
import ProsePalDomain
import SwiftUI

@MainActor
public final class GenerateCardViewModel: ObservableObject {
    @Published public private(set) var isGenerating = false
    @Published public private(set) var response: CardResponse?
    @Published public private(set) var errorMessage: String?

    private let client: MessageWritingClient
    private let clientContext: ClientContext

    public init(
        client: MessageWritingClient,
        clientContext: ClientContext
    ) {
        self.client = client
        self.clientContext = clientContext
    }

    public func generate(intent: CardIntent, requestedLane: GenerationLane = .automatic) async {
        if isGenerating { return }

        isGenerating = true
        errorMessage = nil

        let request = CardRequest(
            intent: intent,
            requestedLane: requestedLane,
            clientContext: clientContext
        )

        do {
            response = try await client.generateCard(request: request)
        } catch let error as GenerationError {
            errorMessage = error.userSafeMessage
        } catch {
            errorMessage = "Message generation failed. Please try again."
        }

        isGenerating = false
    }
}

public struct GenerateCardView: View {
    @StateObject private var viewModel: GenerateCardViewModel

    private let sampleIntent = CardIntent(
        occasion: .birthday,
        relationship: .parent,
        tone: .warm,
        length: .standard,
        localeIdentifier: "en_GB",
        recipientName: "Dad",
        thingsToInclude: ["a quiet cup of tea"],
        userContext: "Keep it gentle and sincere."
    )

    public init(viewModel: @autoclosure @escaping () -> GenerateCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Birthday")
                .font(.largeTitle.bold())

            Text("Warm message for Dad")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.generate(intent: sampleIntent) }
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                } else {
                    Text("Generate")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGenerating)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.response?.messages ?? []) { message in
                Text(message.text)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
}

#Preview {
    GenerateCardView(
        viewModel: GenerateCardViewModel(
            client: TemplateMessageWritingClient(),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    )
}

