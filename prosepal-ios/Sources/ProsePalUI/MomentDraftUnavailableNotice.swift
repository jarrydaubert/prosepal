import Foundation

struct MomentDraftUnavailableNotice {
    var title: String
    var detail: String
    var systemImage: String
    var canRetry: Bool

    static let offline = MomentDraftUnavailableNotice(
        title: String(localized: "Connection needed"),
        detail: String(localized: "Private Draft could not finish offline on this device. Check your connection and try again."),
        systemImage: "wifi.slash",
        canRetry: true
    )
}
