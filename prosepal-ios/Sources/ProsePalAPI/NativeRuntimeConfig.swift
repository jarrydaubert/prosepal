import Foundation

public struct NativeRuntimeConfig: Sendable {
    private let environment: [String: String]
    private let infoDictionary: [String: String]

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) {
        self.environment = environment
        self.infoDictionary = infoDictionary.compactMapValues { value in
            switch value {
            case let string as String:
                string
            case let value as CustomStringConvertible:
                value.description
            default:
                nil
            }
        }
    }

    public func value(named key: String) -> String? {
        if let environmentValue = environment[key]?.trimmedNonEmpty {
            return environmentValue
        }

        return infoDictionary[key]?.trimmedNonEmpty
    }

    public func value(named primaryKey: String, fallback fallbackKey: String) -> String? {
        value(named: primaryKey) ?? value(named: fallbackKey)
    }

    public func url(named key: String) -> URL? {
        guard
            let rawValue = value(named: key),
            let url = URL(string: rawValue),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return nil
        }
        return url
    }

    public func url(named primaryKey: String, fallback fallbackKey: String) -> URL? {
        url(named: primaryKey) ?? url(named: fallbackKey)
    }

    public func list(named key: String) -> [String] {
        guard let rawValue = value(named: key) else { return [] }

        var seen = Set<String>()
        return rawValue
            .split { character in
                character == "," || character == "\n" || character == " "
            }
            .compactMap { item -> String? in
                let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !seen.contains(trimmed) else { return nil }
                seen.insert(trimmed)
                return trimmed
            }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
