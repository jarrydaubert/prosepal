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
        [RelationshipTruthBeadRecord.self]
    }
}
