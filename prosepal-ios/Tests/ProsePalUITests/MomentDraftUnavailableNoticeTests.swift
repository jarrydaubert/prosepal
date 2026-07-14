import Testing
@testable import ProsePalUI

@Test
func offlineDraftNoticeIsHonestAndRetryable() {
    let notice = MomentDraftUnavailableNotice.offline

    #expect(notice.title == "Connection needed")
    #expect(notice.detail == "Private Draft could not finish offline on this device. Check your connection and try again.")
    #expect(notice.systemImage == "wifi.slash")
    #expect(notice.canRetry)
}
