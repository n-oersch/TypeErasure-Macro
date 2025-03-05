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
    func testSimpleProtocol() throws {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto {
            }
            """,
            expandedSource:
            """
            protocol Proto {
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
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testVariableProtocol() throws {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto {
                var name: String { get set }
                var date: Double { get set }
            }
            """,
            expandedSource:
            """
            protocol Proto {
                var name: String { get set }
                var date: Double { get set }
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
            
              var name: String {
                  self.value.name
              }
              var date: Double {
                  self.value.date
              }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testFunctionProtocol() throws {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto {
                func test()
                func parameters(with: String)
                func multiple(first: Bool, second: String) -> Double
            }
            """,
            expandedSource:
            """
            protocol Proto {
                func test()
                func parameters(with: String)
                func multiple(first: Bool, second: String) -> Double
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
            
              func test() {
                  self.value.test()
              }
              func parameters(with: String) {
                  self.value.parameters(with: with)
              }
              func multiple(first: Bool, second: String) -> Double {
                  self.value.multiple(first: first, second: second)
              }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testConformance() {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto: Equatable {
            }
            """,
            expandedSource:
            """
            protocol Proto: Equatable {
            }
            
            enum AnyProto: Equatable {
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
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAll() throws {
        #if canImport(TypeErasureMacros)
        assertMacroExpansion(
            """
            @TypeErasure([ModelA, ModelB])
            protocol Proto: Equatable, Identifiable {
                var name: String { get set }
                var date: Double { get set }
                
                func parameters(with: String)
                func multiple(first: Bool, second: String) -> Double
            }
            """,
            expandedSource:
            """
            protocol Proto: Equatable, Identifiable {
                var name: String { get set }
                var date: Double { get set }
                
                func parameters(with: String)
                func multiple(first: Bool, second: String) -> Double
            }
            
            enum AnyProto: Equatable, Identifiable {
              case modelA(ModelA)
              case modelB(ModelB)
            
              var value: any Proto {
                  switch self {
                  case .modelA(let model as any Proto),
                  .modelB(let model as any Proto):
                      return model
                  }
              }
            
              var name: String {
                  self.value.name
              }
              var date: Double {
                  self.value.date
              }
              func parameters(with: String) {
                  self.value.parameters(with: with)
              }
              func multiple(first: Bool, second: String) -> Double {
                  self.value.multiple(first: first, second: second)
              }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
