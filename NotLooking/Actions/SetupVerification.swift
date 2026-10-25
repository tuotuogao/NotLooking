import Foundation

/// A successful setup test must observe protection engage, then clear while tracking.
/// A disconnect clearing the overlay must never count as a successful return.
struct SetupVerification: Equatable {
    enum Phase { case waitingForTurn, waitingForReturn, passed }
    private(set) var phase: Phase = .waitingForTurn

    mutating func update(isTracking: Bool, isProtected: Bool) {
        guard isTracking else { reset(); return }
        switch phase {
        case .waitingForTurn where isProtected: phase = .waitingForReturn
        case .waitingForReturn where !isProtected: phase = .passed
        default: break
        }
    }

    mutating func reset() { phase = .waitingForTurn }
}
