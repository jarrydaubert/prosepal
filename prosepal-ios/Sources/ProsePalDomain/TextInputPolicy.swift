import Foundation

public enum ProsePalTextLimit {
    public static let personName = 80
    public static let momentDetail = 1_200
    public static let relationshipMemory = 500
    public static let voiceCard = 500
    public static let draft = 4_000
}

public enum ProsePalTextInput {
    public static func personName(_ value: String) -> String {
        let singleLine = value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return limited(singleLine, to: ProsePalTextLimit.personName)
    }

    public static func momentDetail(_ value: String) -> String {
        normalizedMultiline(value, limit: ProsePalTextLimit.momentDetail)
    }

    public static func relationshipMemory(_ value: String) -> String {
        normalizedMultiline(value, limit: ProsePalTextLimit.relationshipMemory)
    }

    public static func voiceCard(_ value: String) -> String {
        normalizedMultiline(value, limit: ProsePalTextLimit.voiceCard)
    }

    public static func draft(_ value: String) -> String {
        normalizedMultiline(value, limit: ProsePalTextLimit.draft)
    }

    public static func limited(_ value: String, to limit: Int) -> String {
        String(value.prefix(limit))
    }

    private static func normalizedMultiline(_ value: String, limit: Int) -> String {
        limited(
            value.trimmingCharacters(in: .whitespacesAndNewlines),
            to: limit
        )
    }
}
