import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

protocol ToursProto {
    var id: String { get set }
    var name: String { get set }
}

public struct TypeErasureMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let originProtocol = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }
        
        guard case .argumentList(let arguments) = node.arguments,
              let arrayExpr = arguments.first?.expression.as(ArrayExprSyntax.self)?.elements else {
            return []
        }
        let listOfValues = arrayExpr.compactMap { val in
            let singleItem = val.trimmed
            return singleItem
        }
        var enums = ""
        for i in listOfValues {
            enums += "case \(i.trimmedDescription.lowercased())(\(i))\n"
        }
        return ["""
        enum Any\(originProtocol.name): Equatable {
            \(raw: enums)
        }
        """]
    }
}
@main
struct TypeErasurePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TypeErasureMacro.self,
    ]
}
