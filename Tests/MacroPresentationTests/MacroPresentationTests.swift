import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacroPresentationMacros)
import MacroPresentationMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "EnumTitle": EnumTitleMacro.self,
    "EnumCodingKeys": EnumCodingKeysMacro.self
]
#endif

final class MacroPresentationTests: XCTestCase {
    func testEnumTitleMacro() throws {
        assertMacroExpansion(
"""
@EnumTitle
enum StatePlayer: Int {
    case play(String)
    case pause
    case stop
}
"""
,expandedSource: """
enum StatePlayer: Int {
    case play(String)
    case pause
    case stop

    var title: String {
        switch self {
        case .play:
            return "play"
        case .pause:
            return "pause"
        case .stop:
            return "stop"
        }
    }
}
""",
macros: testMacros)
    }
    
    func testEnumCodingsKeys() throws {
        assertMacroExpansion("""
@EnumCodingKeys
struct LogoutUser: Encodable {
    let refreshToken: String
    let deviceID: String
}
"""
, expandedSource: """
struct LogoutUser: Encodable {
    let refreshToken: String
    let deviceID: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "RefreshToken"
        case deviceID = "DeviceID"
    }
}
""",
macros: testMacros)
    }
    
    func testDiagnosticEnumTitleMacro() throws {
        assertMacroExpansion(
"""
@EnumTitle
struct Diagnostic {
}
"""
, expandedSource: """
struct Diagnostic {
}
"""
, diagnostics: [DiagnosticSpec(message: EnumInitError.onlyApplicableToEnum.description, line: #line, column: #column)]
,macros: testMacros)
    }
    
    func testMacro() throws {
        #if canImport(MacroPresentationMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(MacroPresentationMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
