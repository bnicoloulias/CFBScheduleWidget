import Foundation

/// Where the app's schedule request currently stands.
enum LoadState {
    case idle
    case loading
    case loaded(Schedule)
    case failed(String)
}
