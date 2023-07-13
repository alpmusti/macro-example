import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import TYMacrosMacros

let testMacros: [String: Macro.Type] = [
    "Endpoint": EndpointMacro.self,
    "ABConfig": ABConfig.self,
    "ABConfigurables": ABConfigurables.self
]

final class TYMacrosTests: XCTestCase {
//    func testMacros() {
//        assertMacroExpansion(
//            """
//            @ABConfig(args: ABConfigArguments(firebaseDimension: \"ios_abtest_1\"))
//            struct SocialAB {}
//            """,
//            expandedSource: "",
//            macros: ["ABConfig": ABConfig.self]
//        )
//    }

    func testABConfigurableMacro() {
        assertMacroExpansion(
            """
            @ABConfigurables
            struct TYABTestDefinitions {
                private init() { }

                @ABConfig(args: ABConfigArguments(firebaseDimension: "ios_abtest_1"))
                struct SocialAB {}

                @ABConfig(args: ABConfigArguments(firebaseDimension: "ios_abtest_2"))
                struct HomepageAB {}
            }
            """,
            expandedSource: "",
            macros: testMacros
        )
    }
}
