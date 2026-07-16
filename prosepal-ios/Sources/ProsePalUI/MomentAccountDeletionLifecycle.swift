import Foundation

public extension MomentModel {
    /// Account-deletion lifecycle reset: cancels any in-flight generation and
    /// removes every piece of user content this model holds — composer input,
    /// the current draft and its alternatives/history, pressure
    /// acknowledgement (cleared by the draft change), and the persisted
    /// recovery snapshot — so nothing from the deleted account can remain
    /// visible or reappear on relaunch.
    func resetForAccountDeletion() {
        startNewMoment()
    }
}
