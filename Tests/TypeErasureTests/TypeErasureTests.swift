import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(TypeErasureMacros)
import TypeErasureMacros

let testMacros: [String: Macro.Type] = [
    "TypeErasure": TypeErasureMacro.self,
]
#endif

final class TypeErasureTests: XCTestCase {
    func testMacro() throws {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto: Equatable {
              var name: String { get set }
            }
            struct ModelA: Proto {
              var name = "ModelA"
              var x = 1
            }
            struct ModelB: Proto {
              var name = "ModelB"
              var x = "10"
            }
            """,
            expandedSource:
            """
            protocol Proto: Equatable {
              var name: String { get set }
            }
            
            enum AnyProto {
              case modelA(ModelA)
              case modelB(ModelB)
            
              var value: any Proto {
                switch self {
                case .modelA(let model as any Proto),
                .modelB(let model as any Proto):
                  return model
                }
              }
            }
            struct ModelA: Proto {
              var name = "ModelA"
              var x = 1
            }
            struct ModelB: Proto {
              var name = "ModelB"
              var x = "10"
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
