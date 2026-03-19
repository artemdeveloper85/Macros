import MacroPresentation

enum State {
    case west, east
    case north, south
}

@EnumCodingKeys(style: .pascalCase)
struct LogoutUser: Decodable {
    let refreshToken: String
    let deviceId: String
}

@EnumCodingKeys()
class Student: Codable {
    let firstName: String
    let lastName: String
}



