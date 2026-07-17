import Foundation

extension URLError {
    var isProsePalConnectivityFailure: Bool {
        switch code {
        case .notConnectedToInternet,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .networkConnectionLost:
            true
        default:
            false
        }
    }
}
