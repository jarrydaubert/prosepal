import ProsePalAPI

final class TestOnlineWritingPermissionStore: OnlineWritingPermissionStoring, @unchecked Sendable {
    private var permissionState: OnlineWritingPermissionState

    init(state: OnlineWritingPermissionState = .currentGrant) {
        permissionState = state
    }

    func state() -> OnlineWritingPermissionState {
        permissionState
    }

    func grantCurrentPolicy() {
        permissionState = .currentGrant
    }

    func revoke() {
        permissionState = .notGranted
    }
}

func grantedOnlineWritingPermissionStore() -> TestOnlineWritingPermissionStore {
    TestOnlineWritingPermissionStore()
}
