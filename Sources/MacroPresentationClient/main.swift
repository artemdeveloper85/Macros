import MacroPresentation

@EnumTitle
enum State {
    case west, east
    case north, south
}

@EnumCodingKeys
struct LogoutUser: Decodable {
    let refreshToken, deviceID: String
}
