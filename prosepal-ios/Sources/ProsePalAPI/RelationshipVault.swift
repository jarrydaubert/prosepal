import Foundation
import ProsePalDomain
import SwiftData

@Model
public final class RelationshipTruthBeadRecord {
    public var id: UUID
    public var personName: String
    public var text: String
    public var isUserApproved: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        text: String,
        isUserApproved: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.text = text
        self.isUserApproved = isUserApproved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var truthBead: TruthBead {
        TruthBead(
            id: id,
            personName: personName,
            text: text,
            isUserApproved: isUserApproved,
            createdAt: createdAt
        )
    }
}

public enum RelationshipVaultSchema {
    public static var models: [any PersistentModel.Type] {
        [
            RelationshipTruthBeadRecord.self,
            SavedMomentDraftRecord.self
        ]
    }
}

@Model
public final class SavedMomentDraftRecord {
    public var id: UUID
    public var personName: String
    public var relationshipRawValue: String
    public var occasionRawValue: String
    public var registerRawValue: String
    public var toneRawValue: String
    public var lengthRawValue: String
    public var spellingPreferenceRawValue: String
    public var laneRawValue: String
    public var trueThing: String
    public var messageText: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        relationshipRawValue: String,
        occasionRawValue: String,
        registerRawValue: String,
        toneRawValue: String,
        lengthRawValue: String,
        spellingPreferenceRawValue: String,
        laneRawValue: String,
        trueThing: String,
        messageText: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.relationshipRawValue = relationshipRawValue
        self.occasionRawValue = occasionRawValue
        self.registerRawValue = registerRawValue
        self.toneRawValue = toneRawValue
        self.lengthRawValue = lengthRawValue
        self.spellingPreferenceRawValue = spellingPreferenceRawValue
        self.laneRawValue = laneRawValue
        self.trueThing = trueThing
        self.messageText = messageText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(
        moment: MomentInput,
        messageText: String,
        lane: MomentDraftLane,
        createdAt: Date = Date()
    ) {
        self.init(
            personName: moment.personName,
            relationshipRawValue: moment.relationship.rawValue,
            occasionRawValue: moment.occasion.rawValue,
            registerRawValue: moment.register.rawValue,
            toneRawValue: moment.tone.rawValue,
            lengthRawValue: moment.length.rawValue,
            spellingPreferenceRawValue: moment.spellingPreference.rawValue,
            laneRawValue: lane.rawValue,
            trueThing: moment.trueThing,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    public var relationship: Relationship {
        Relationship(rawValue: relationshipRawValue) ?? .closeFriend
    }

    public var occasion: Occasion {
        Occasion(rawValue: occasionRawValue) ?? .birthday
    }

    public var register: MomentRegister {
        MomentRegister(rawValue: registerRawValue) ?? .react
    }

    public var tone: Tone {
        Tone(rawValue: toneRawValue) ?? .heartfelt
    }

    public var length: MessageLength {
        MessageLength(rawValue: lengthRawValue) ?? .standard
    }

    public var lane: MomentDraftLane {
        MomentDraftLane(rawValue: laneRawValue) ?? .privateDraft
    }

    public var title: String {
        personName.isEmpty ? occasion.displayName : personName
    }

    public var subtitle: String {
        "\(occasion.displayName) · \(relationship.displayName)"
    }
}
