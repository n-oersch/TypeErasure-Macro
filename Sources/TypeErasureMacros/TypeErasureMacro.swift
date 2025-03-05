import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

protocol ToursProto {
    var id: String { get set }
    var name: String { get set }
}

/// Creates a TypeErased `Any[Protocol]` enum with all values of the Protocol and cases for all given types
///
/// Example:
/// ```
/// @TypeErasure([ModelA, ModelB])
/// protocol Proto {
///   var x: String { get set }
/// }
/// ```
/// adds the following enum:
/// ```
/// enum AnyProto {
///   case modelA(ModelA)
///   case modelB(ModelB)
///
///   var value: any Proto {
///     switch self {
///     case .modelA(let val as any Proto),
///          .modelB(let val as any Proto):
///       return val
///     }
///   }
///   var x: String {
///     self.value.x
///   }
/// }
/// ```
public struct TypeErasureMacro: PeerMacro {
    
    // MARK: PeerMacro impl
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        // check if the declaration the macro is applied to is a Protocol
        guard let originProtocol = declaration.as(ProtocolDeclSyntax.self) else {
            fatalError("Can only be applied to a Protocol")
        }
        
        // the arguments need to be an array, but this should already be handled by the type-checker before resolving the macro
        guard case .argumentList(let arguments) = node.arguments,
              let argArray = arguments.first?.expression.as(ArrayExprSyntax.self)?.elements else {
            fatalError("Please append the Types that conform to this Protocol as an array like `@TypeErasure([ModelA, ModelB])`")
        }
        // the arguments should be `DeclReferenceExpr`, so references to Declarations (like types)
        let listOfTypes = argArray.compactMap { argument in
            guard let type = argument.expression.as(DeclReferenceExprSyntax.self) else {
                fatalError("Argument is not a Type")
            }
            return type.baseName.text
        }
        
        let enums = buildEnumCases(with: listOfTypes)
        let anyName = "Any\(originProtocol.name.trimmed)"
        return ["""
        enum \(raw: anyName) {
          \(raw: enums)
        }
        """]
    }
    
    private static func buildEnumCases(with listOfTypes: [String]) -> String {
        var enums = ""
        for typeName in listOfTypes {
            enums += "case \(enumName(of: typeName))(\(typeName))\n"
        }
        enums.removeLast()
        return enums
    }
    
    private static func enumName(of typeName: String) -> String {
        return "\(typeName.first!.lowercased())\(typeName.dropFirst())"
    }
}
@main
struct TypeErasurePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TypeErasureMacro.self,
    ]
}
