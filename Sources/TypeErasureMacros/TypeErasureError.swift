enum TypeErasureError: Error, CustomStringConvertible {
    case usage
    case toProtocol

    var description: String {
        switch self {
        case .usage:
            return "Include Types that conform to the Protocol like this `@TypeErasure([ModelA, ModelB])"
        case .toProtocol:
            return "@TypeErasure is only usable on a Protocol"
        }
    }
}
