import Foundation
import ProsePalDomain
import UniformTypeIdentifiers
import UIKit

@MainActor
final class ShareViewController: UIViewController {
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let previewLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var sharedText: String?
    private var sourceURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()

        Task {
            await loadSharedContext()
        }
    }

    private func buildView() {
        view.backgroundColor = .systemBackground

        titleLabel.text = "Open in ProsePal"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true

        bodyLabel.text = "Ready to continue when you are."
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.adjustsFontForContentSizeCategory = true

        previewLabel.text = "Reading shared context..."
        previewLabel.font = .preferredFont(forTextStyle: .callout)
        previewLabel.textColor = .label
        previewLabel.numberOfLines = 6
        previewLabel.adjustsFontForContentSizeCategory = true

        openButton.setTitle("Open ProsePal", for: .normal)
        openButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        openButton.isEnabled = false
        openButton.addTarget(self, action: #selector(openProsePal), for: .touchUpInside)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, openButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, previewLabel, buttonStack])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadSharedContext() async {
        let providers = inputItemProviders
        var fragments = [String]()
        var firstURL: URL?

        for provider in providers {
            if let url = await provider.prosePalLoadedURL() {
                if firstURL == nil {
                    firstURL = url
                }
                fragments.append(url.absoluteString)
            }
            if let text = await provider.prosePalLoadedString() {
                fragments.append(text)
            }
        }

        sharedText = SharedMomentLaunchPayload.sanitized(fragments.joined(separator: "\n\n"))
        sourceURL = firstURL
        openButton.isEnabled = sharedText != nil || sourceURL != nil
        previewLabel.text = sharedText ?? "No usable text or URL was found in this share."
    }

    private var inputItemProviders: [NSItemProvider] {
        extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []
    }

    @objc
    private func openProsePal() {
        let payload = SharedMomentLaunchPayload(text: sharedText, sourceURL: sourceURL)
        let didSave = SharedMomentLaunchStore().save(payload)
        guard didSave,
              let url = MomentDeepLink.momentURL(source: MomentLaunchSource.shareExtension) else {
            previewLabel.text = "ProsePal could not prepare this shared context."
            return
        }

        extensionContext?.open(url) { [weak self] opened in
            Task { @MainActor in
                guard opened else {
                    self?.previewLabel.text = "ProsePal could not be opened from this share."
                    return
                }
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    @objc
    private func cancel() {
        extensionContext?.cancelRequest(withError: ShareExtensionError.cancelled)
    }
}

private enum ShareExtensionError: LocalizedError {
    case cancelled

    var errorDescription: String? {
        "The ProsePal share was cancelled."
    }
}

private extension NSItemProvider {
    @MainActor
    func prosePalLoadedString() async -> String? {
        let textTypes = [UTType.plainText.identifier, UTType.text.identifier]
        guard let typeIdentifier = textTypes.first(where: hasItemConformingToTypeIdentifier) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                } else if let data = item as? Data {
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    @MainActor
    func prosePalLoadedURL() async -> URL? {
        let typeIdentifier = UTType.url.identifier
        guard hasItemConformingToTypeIdentifier(typeIdentifier) else { return nil }

        return await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let text = item as? String {
                    continuation.resume(returning: URL(string: text))
                } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: URL(string: text))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
