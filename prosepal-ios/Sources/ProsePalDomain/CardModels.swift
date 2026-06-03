import Foundation

public enum Occasion: String, Codable, CaseIterable, Sendable, Identifiable {
    case birthday
    case thankYou
    case sympathy
    case wedding
    case christmas
    case getWell
    case congrats
    case mothersDay
    case fathersDay
    case baby
    case graduation
    case anniversary
    case valentinesDay
    case thinkingOfYou
    case newYear
    case engagement
    case kidsBirthday
    case justBecause
    case housewarming
    case retirement
    case newJob
    case encouragement
    case easter
    case thanksgiving
    case halloween
    case apology
    case farewell
    case goodLuck
    case promotion
    case thankYouTeacher
    case thankYouHealthcare
    case thankYouService
    case hanukkah
    case diwali
    case eid
    case lunarNewYear
    case kwanzaa
    case petBirthday
    case newPet
    case petSympathy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .birthday: "Birthday"
        case .thankYou: "Thank You"
        case .sympathy: "Sympathy"
        case .wedding: "Wedding"
        case .christmas: "Christmas"
        case .getWell: "Get Well"
        case .congrats: "Congrats"
        case .mothersDay: "Mother's Day"
        case .fathersDay: "Father's Day"
        case .baby: "New Baby"
        case .graduation: "Graduation"
        case .anniversary: "Anniversary"
        case .valentinesDay: "Valentine's Day"
        case .thinkingOfYou: "Thinking of You"
        case .newYear: "New Year"
        case .engagement: "Engagement"
        case .kidsBirthday: "Kid's Birthday"
        case .justBecause: "Just Because"
        case .housewarming: "New Home"
        case .retirement: "Retirement"
        case .newJob: "New Job"
        case .encouragement: "Encouragement"
        case .easter: "Easter"
        case .thanksgiving: "Thanksgiving"
        case .halloween: "Halloween"
        case .apology: "Apology"
        case .farewell: "Farewell"
        case .goodLuck: "Good Luck"
        case .promotion: "Promotion"
        case .thankYouTeacher: "Thank You Teacher"
        case .thankYouHealthcare: "Thank You Healthcare"
        case .thankYouService: "Thank You for Service"
        case .hanukkah: "Hanukkah"
        case .diwali: "Diwali"
        case .eid: "Eid"
        case .lunarNewYear: "Lunar New Year"
        case .kwanzaa: "Kwanzaa"
        case .petBirthday: "Pet Birthday"
        case .newPet: "New Pet"
        case .petSympathy: "Pet Loss"
        }
    }

    public var generationHint: String {
        switch self {
        case .birthday: "birthday celebration - joyful wishes for their special day and the year ahead"
        case .thankYou: "expressing genuine, specific gratitude - make it personal and meaningful"
        case .sympathy: "offering condolences and comfort - acknowledge grief with warmth, avoid cliches, be genuinely supportive"
        case .wedding: "wedding celebration - heartfelt wishes for their journey together as a married couple"
        case .christmas: "warm Christmas wishes - capture the spirit of the season with joy and goodwill"
        case .getWell: "get well wishes - encouraging and warm without minimizing their situation"
        case .congrats: "congratulations on an achievement - celebrate their hard work and success enthusiastically"
        case .mothersDay: "celebrating a mother on Mother's Day - express love, appreciation, and gratitude for all she does"
        case .fathersDay: "celebrating a father on Father's Day - express love, appreciation, and gratitude for his guidance"
        case .baby: "welcoming a new baby - joyful congratulations for the new parents on this life-changing moment"
        case .graduation: "graduation celebration - honor their achievement and wish them well on the exciting path ahead"
        case .anniversary: "celebrating an anniversary milestone - honor the journey and love they share together"
        case .valentinesDay: "expressing romantic love on Valentine's Day - heartfelt and genuine, not cheesy"
        case .thinkingOfYou: "letting someone know you care - warm thoughts that brighten their day"
        case .newYear: "New Year wishes - hopeful sentiments for happiness, health, and success in the year ahead"
        case .engagement: "congratulating on an engagement - celebrate this exciting step toward marriage"
        case .kidsBirthday: "fun, child-appropriate birthday celebration - playful and age-appropriate excitement"
        case .justBecause: "sending love or appreciation for no special reason - spontaneous warmth and connection"
        case .housewarming: "congratulating on a new home - warm wishes for happiness and memories in their new space"
        case .retirement: "celebrating retirement - honor their career and wish them well for this exciting new chapter"
        case .newJob: "congratulating on a new job - celebrate this career milestone and wish them success"
        case .encouragement: "offering support during a challenge - uplifting and genuine without toxic positivity"
        case .easter: "warm Easter wishes - celebrate spring, renewal, and joy of the season"
        case .thanksgiving: "Thanksgiving wishes - express gratitude and warm thoughts for the holiday"
        case .halloween: "fun Halloween greetings - playful spooky wishes appropriate for the occasion"
        case .apology: "sincere apology - acknowledge what went wrong, express genuine remorse without making excuses"
        case .farewell: "saying goodbye - heartfelt farewell that honors the relationship and wishes them well"
        case .goodLuck: "wishing good luck - encouraging words for an upcoming challenge, interview, or big moment"
        case .promotion: "congratulating on a promotion - celebrate their hard work and well-deserved recognition"
        case .thankYouTeacher: "thanking a teacher - express gratitude for their dedication, patience, and impact on learning"
        case .thankYouHealthcare: "thanking a healthcare worker - express gratitude for their care, compassion, and expertise"
        case .thankYouService: "thanking a veteran or service member - honor their sacrifice and service to the country"
        case .hanukkah: "warm Hanukkah wishes - celebrate the Festival of Lights with joy and tradition"
        case .diwali: "Diwali wishes - celebrate the festival of lights with joy, prosperity, and new beginnings"
        case .eid: "warm Eid wishes - celebrate with joy, peace, blessings, and togetherness"
        case .lunarNewYear: "Lunar New Year wishes - celebrate with prosperity, good fortune, and family blessings"
        case .kwanzaa: "Kwanzaa wishes - honor the principles of unity, creativity, faith, and community"
        case .petBirthday: "fun pet birthday celebration - playful wishes for a beloved furry family member"
        case .newPet: "welcoming a new pet - congratulate them on their new furry, feathered, or scaly family member"
        case .petSympathy: "condolences for pet loss - acknowledge their grief with warmth and understanding for a beloved companion"
        }
    }

    public var group: OccasionGroup {
        switch self {
        case .birthday, .thankYou, .sympathy, .wedding, .christmas:
            .mostUsed
        case .getWell, .congrats, .mothersDay, .fathersDay, .baby:
            .commonLifeEvents
        case .graduation, .anniversary, .valentinesDay, .thinkingOfYou, .newYear, .engagement, .kidsBirthday, .justBecause:
            .milestones
        case .housewarming, .retirement, .newJob, .encouragement:
            .lifeChanges
        case .easter, .thanksgiving, .halloween:
            .seasonal
        case .apology, .farewell, .goodLuck, .promotion:
            .specificSituations
        case .thankYouTeacher, .thankYouHealthcare, .thankYouService:
            .appreciation
        case .hanukkah, .diwali, .eid, .lunarNewYear, .kwanzaa:
            .culturalHolidays
        case .petBirthday, .newPet, .petSympathy:
            .pets
        }
    }

    public var symbolName: String {
        switch self {
        case .birthday: "birthday.cake"
        case .thankYou: "hands.sparkles"
        case .sympathy: "heart.text.square"
        case .wedding: "heart.circle"
        case .christmas: "gift"
        case .getWell: "cross.case"
        case .congrats: "sparkles"
        case .mothersDay: "figure.and.child.holdinghands"
        case .fathersDay: "figure.2.and.child.holdinghands"
        case .baby: "figure.and.child.holdinghands"
        case .graduation: "graduationcap"
        case .anniversary: "heart"
        case .valentinesDay: "heart.fill"
        case .thinkingOfYou: "paperplane"
        case .newYear: "calendar.badge.clock"
        case .engagement: "diamond"
        case .kidsBirthday: "balloon.2"
        case .justBecause: "heart.square"
        case .housewarming: "house"
        case .retirement: "beach.umbrella"
        case .newJob: "briefcase"
        case .encouragement: "figure.strengthtraining.traditional"
        case .easter: "leaf"
        case .thanksgiving: "fork.knife"
        case .halloween: "moon.stars"
        case .apology: "arrow.uturn.backward.heart"
        case .farewell: "hand.wave"
        case .goodLuck: "clover"
        case .promotion: "chart.line.uptrend.xyaxis"
        case .thankYouTeacher: "book"
        case .thankYouHealthcare: "stethoscope"
        case .thankYouService: "medal"
        case .hanukkah: "sparkles"
        case .diwali: "flame"
        case .eid: "moon"
        case .lunarNewYear: "lantern"
        case .kwanzaa: "candle"
        case .petBirthday: "pawprint"
        case .newPet: "pawprint.circle"
        case .petSympathy: "rainbow"
        }
    }

    public var searchText: String {
        "\(displayName) \(group.displayName) \(generationHint)"
    }

    public static var featuredCases: [Occasion] {
        [.birthday, .thankYou, .sympathy, .wedding, .christmas, .getWell]
    }
}

public enum OccasionGroup: String, CaseIterable, Sendable, Identifiable {
    case mostUsed
    case commonLifeEvents
    case milestones
    case lifeChanges
    case seasonal
    case specificSituations
    case appreciation
    case culturalHolidays
    case pets

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .mostUsed: "Most Used"
        case .commonLifeEvents: "Common Life Events"
        case .milestones: "Milestones"
        case .lifeChanges: "Life Changes"
        case .seasonal: "Seasonal"
        case .specificSituations: "Specific Situations"
        case .appreciation: "Appreciation"
        case .culturalHolidays: "Cultural Holidays"
        case .pets: "Pets"
        }
    }
}

public enum Relationship: String, Codable, CaseIterable, Sendable, Identifiable {
    case closeFriend
    case family
    case parent
    case child
    case sibling
    case grandparent
    case grandchild
    case romantic
    case colleague
    case boss
    case mentor
    case teacher
    case neighbor
    case acquaintance

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .closeFriend: "Close Friend"
        case .family: "Family"
        case .parent: "Parent"
        case .child: "Child"
        case .sibling: "Sibling"
        case .grandparent: "Grandparent"
        case .grandchild: "Grandchild"
        case .romantic: "Partner"
        case .colleague: "Colleague"
        case .boss: "Boss"
        case .mentor: "Mentor"
        case .teacher: "Teacher"
        case .neighbor: "Neighbor"
        case .acquaintance: "Acquaintance"
        }
    }

    public var generationHint: String {
        switch self {
        case .closeFriend: "a close friend - someone you share inside jokes with and can be yourself around"
        case .family: "a general family member - warm and familiar but not specifically defined"
        case .parent: "a parent (mom or dad) - deep gratitude, love, and respect for all they do"
        case .child: "a son or daughter - parental pride, unconditional love, and encouragement"
        case .sibling: "a brother or sister - that unique mix of teasing, loyalty, and lifelong bond"
        case .grandparent: "a grandparent - deep respect, appreciation for their wisdom and love"
        case .grandchild: "a grandchild - grandparental adoration, pride, and warm affection"
        case .romantic: "a romantic partner or spouse - intimate, loving, can reference shared experiences"
        case .colleague: "a work colleague - friendly but professional, appropriate for the workplace"
        case .boss: "a boss or manager - respectful, professional, appreciative of their leadership"
        case .mentor: "a mentor or guide - gratitude for their guidance, wisdom, and investment in your growth"
        case .teacher: "a teacher or educator - appreciation for their patience, knowledge, and impact"
        case .neighbor: "a neighbor - friendly and warm, community-minded, appropriate neighborly tone"
        case .acquaintance: "an acquaintance or casual contact - polite, warm but not overly familiar"
        }
    }

    public var group: RelationshipGroup {
        switch self {
        case .closeFriend, .family, .parent, .child, .sibling, .grandparent, .grandchild, .romantic:
            .personal
        case .colleague, .boss, .mentor, .teacher:
            .professional
        case .neighbor, .acquaintance:
            .community
        }
    }

    public var symbolName: String {
        switch self {
        case .closeFriend: "person.2"
        case .family: "figure.2.and.child.holdinghands"
        case .parent: "figure.and.child.holdinghands"
        case .child: "figure.child"
        case .sibling: "person.2.circle"
        case .grandparent: "person.crop.circle"
        case .grandchild: "figure.and.child.holdinghands"
        case .romantic: "heart"
        case .colleague: "briefcase"
        case .boss: "person.crop.rectangle"
        case .mentor: "graduationcap"
        case .teacher: "book"
        case .neighbor: "house"
        case .acquaintance: "person.wave.2"
        }
    }
}

public enum RelationshipGroup: String, CaseIterable, Sendable, Identifiable {
    case personal
    case professional
    case community

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .personal: "Personal"
        case .professional: "Professional"
        case .community: "Community"
        }
    }
}

public enum Tone: String, Codable, CaseIterable, Sendable, Identifiable {
    case heartfelt
    case casual
    case funny
    case formal
    case inspirational
    case playful
    case sarcastic
    case nostalgic
    case poetic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .heartfelt: "Heartfelt"
        case .casual: "Casual"
        case .funny: "Funny"
        case .formal: "Formal"
        case .inspirational: "Inspirational"
        case .playful: "Playful"
        case .sarcastic: "Sarcastic"
        case .nostalgic: "Nostalgic"
        case .poetic: "Poetic"
        }
    }

    public var description: String {
        switch self {
        case .heartfelt: "Warm and sincere"
        case .casual: "Friendly and relaxed"
        case .funny: "Humorous and witty"
        case .formal: "Professional and polished"
        case .inspirational: "Uplifting and motivational"
        case .playful: "Cheeky and teasing"
        case .sarcastic: "Dry and ironic"
        case .nostalgic: "Reflective and sentimental"
        case .poetic: "Lyrical and elegant"
        }
    }

    public var generationHint: String {
        switch self {
        case .heartfelt: "warm, sincere, and emotionally touching - express genuine feeling without being overly sentimental"
        case .casual: "friendly, relaxed, and conversational - like talking to a friend, natural and easy"
        case .funny: "humorous, witty, and lighthearted - clever wordplay and gentle humor that makes them smile"
        case .formal: "professional, respectful, and polished - appropriate for colleagues, bosses, or formal occasions"
        case .inspirational: "uplifting, motivational, and encouraging - genuinely inspiring without resorting to cliches"
        case .playful: "cheeky, teasing, and fun - gentle sarcasm and inside-joke energy between close friends"
        case .sarcastic: "dry wit, ironic, and subtly mocking - affectionate roasting between people who get each other"
        case .nostalgic: "reflective, sentimental about shared history - honors memories and the journey together"
        case .poetic: "lyrical, beautiful language with imagery - elevated prose that reads like poetry without being forced"
        }
    }

    public var symbolName: String {
        switch self {
        case .heartfelt: "heart"
        case .casual: "bubble.left.and.bubble.right"
        case .funny: "theatermasks"
        case .formal: "doc.text"
        case .inspirational: "sparkles"
        case .playful: "party.popper"
        case .sarcastic: "quote.bubble"
        case .nostalgic: "clock.arrow.circlepath"
        case .poetic: "text.quote"
        }
    }
}

public enum MessageLength: String, Codable, CaseIterable, Sendable, Identifiable {
    case brief
    case standard
    case detailed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .brief: "Brief"
        case .standard: "Standard"
        case .detailed: "Detailed"
        }
    }

    public var description: String {
        switch self {
        case .brief: "Short & sweet"
        case .standard: "Just right"
        case .detailed: "Longer & personal"
        }
    }

    public var generationHint: String {
        switch self {
        case .brief: "1-2 sentences"
        case .standard: "3-4 sentences"
        case .detailed: "5-7 sentences"
        }
    }

    public var symbolName: String {
        switch self {
        case .brief: "bolt"
        case .standard: "sparkles"
        case .detailed: "heart.text.square"
        }
    }
}

public enum SpellingPreference: String, Codable, CaseIterable, Sendable, Identifiable {
    case automatic
    case us
    case uk

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .us: "US English"
        case .uk: "UK English"
        }
    }

    public var exampleText: String {
        switch self {
        case .automatic: "Use device locale"
        case .us: "Mom, favorite"
        case .uk: "Mum, favourite"
        }
    }

    public var localeIdentifier: String {
        switch self {
        case .automatic: Locale.current.identifier
        case .us: "en_US"
        case .uk: "en_GB"
        }
    }
}

public enum GenerationLane: String, Codable, CaseIterable, Sendable {
    case automatic
    case standard
    case premium
    case local
    case template
}

public extension GenerationLane {
    var displayName: String {
        switch self {
        case .automatic: "Auto"
        case .standard: "Standard"
        case .premium: "Premium"
        case .local: "Local"
        case .template: "Template"
        }
    }
}

public enum FallbackStatus: String, Codable, Sendable {
    case none
    case degradedToStandard
    case degradedToTemplate
    case failed
}

public enum RetryEligibility: String, Codable, Sendable {
    case eligible
    case ineligible
    case waitBeforeRetry
}

public struct CardIntent: Codable, Equatable, Sendable {
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var spellingPreference: SpellingPreference
    public var localeIdentifier: String
    public var recipientName: String?
    public var thingsToInclude: [String]
    public var thingsToAvoid: [String]
    public var userContext: String?

    public init(
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength = .standard,
        spellingPreference: SpellingPreference = .automatic,
        localeIdentifier: String? = nil,
        recipientName: String? = nil,
        thingsToInclude: [String] = [],
        thingsToAvoid: [String] = [],
        userContext: String? = nil
    ) {
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.spellingPreference = spellingPreference
        self.localeIdentifier = localeIdentifier ?? spellingPreference.localeIdentifier
        self.recipientName = recipientName
        self.thingsToInclude = thingsToInclude
        self.thingsToAvoid = thingsToAvoid
        self.userContext = userContext
    }
}

public struct ClientContext: Codable, Equatable, Sendable {
    public var appVersion: String
    public var buildNumber: String
    public var platform: String
    public var installationId: String?

    public init(
        appVersion: String,
        buildNumber: String,
        platform: String = "ios",
        installationId: String? = nil
    ) {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.installationId = installationId
    }
}

public struct CardRequest: Codable, Equatable, Sendable {
    public static let currentPromptContractVersion = 1
    public static let currentOutputContractVersion = 1

    public var idempotencyKey: String
    public var intent: CardIntent
    public var requestedLane: GenerationLane
    public var clientContext: ClientContext
    public var promptContractVersion: Int
    public var outputContractVersion: Int

    public init(
        idempotencyKey: String = UUID().uuidString,
        intent: CardIntent,
        requestedLane: GenerationLane = .automatic,
        clientContext: ClientContext,
        promptContractVersion: Int = CardRequest.currentPromptContractVersion,
        outputContractVersion: Int = CardRequest.currentOutputContractVersion
    ) {
        self.idempotencyKey = idempotencyKey
        self.intent = intent
        self.requestedLane = requestedLane
        self.clientContext = clientContext
        self.promptContractVersion = promptContractVersion
        self.outputContractVersion = outputContractVersion
    }
}

public struct GeneratedMessage: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var text: String

    public init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}

public struct UsageSummary: Codable, Equatable, Sendable {
    public var remaining: Int?
    public var limit: Int?
    public var resetsAt: Date?

    public init(remaining: Int? = nil, limit: Int? = nil, resetsAt: Date? = nil) {
        self.remaining = remaining
        self.limit = limit
        self.resetsAt = resetsAt
    }
}

public struct QualityCheckSummary: Codable, Equatable, Sendable {
    public var passed: Bool
    public var userSafeNote: String?

    public init(passed: Bool, userSafeNote: String? = nil) {
        self.passed = passed
        self.userSafeNote = userSafeNote
    }
}

public struct UserSafeError: Codable, Equatable, Sendable {
    public var code: String
    public var message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct CardResponse: Codable, Equatable, Sendable {
    public var messages: [GeneratedMessage]
    public var laneUsed: GenerationLane
    public var fallbackStatus: FallbackStatus
    public var qualityCheck: QualityCheckSummary?
    public var usage: UsageSummary?
    public var retryEligibility: RetryEligibility
    public var userSafeError: UserSafeError?
    public var promptContractVersion: Int
    public var outputContractVersion: Int

    public init(
        messages: [GeneratedMessage],
        laneUsed: GenerationLane,
        fallbackStatus: FallbackStatus = .none,
        qualityCheck: QualityCheckSummary? = nil,
        usage: UsageSummary? = nil,
        retryEligibility: RetryEligibility = .ineligible,
        userSafeError: UserSafeError? = nil,
        promptContractVersion: Int = CardRequest.currentPromptContractVersion,
        outputContractVersion: Int = CardRequest.currentOutputContractVersion
    ) {
        self.messages = messages
        self.laneUsed = laneUsed
        self.fallbackStatus = fallbackStatus
        self.qualityCheck = qualityCheck
        self.usage = usage
        self.retryEligibility = retryEligibility
        self.userSafeError = userSafeError
        self.promptContractVersion = promptContractVersion
        self.outputContractVersion = outputContractVersion
    }
}
