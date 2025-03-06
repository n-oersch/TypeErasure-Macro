import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

protocol ToursProto {
    var id: String { get set }
    var name: String { get set }
}

/// Creates a TypeErased `Any[Protocol]` enum with all values of the Protocol and cases for all given types. The given Types need to implement this protocol!
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
            throw TypeErasureError.toProtocol
        }
        
        // the arguments need to be an array, but this should already be handled by the type-checker before resolving the macro
        guard case .argumentList(let arguments) = node.arguments,
              let argArray = arguments.first?.expression.as(ArrayExprSyntax.self)?.elements else {
            throw TypeErasureError.usage
        }
        // the arguments should be `DeclReferenceExpr`, so references to Declarations (like types)
        let listOfTypes = try! argArray.compactMap { argument in
            guard let type = argument.expression.as(DeclReferenceExprSyntax.self) else {
                throw TypeErasureError.usage
            }
            return type.baseName.text
        }
        
        let protocolName = originProtocol.name.trimmed
        let erasedName: TokenSyntax = "Any\(protocolName)"
        return ["""
        enum \(erasedName)\(addedConformances(of: originProtocol)) {
          \(enumCasesDefinition(with: listOfTypes))
        
          \(protocolVarDefinition(with: listOfTypes, as: protocolName))
        
          \(passthroughMembersDefinitions(from: originProtocol.memberBlock.members))
        }
        """]
    }
    
    private static func addedConformances(of declaration: ProtocolDeclSyntax) -> TokenSyntax {
        guard let conformanceTypes = declaration.inheritanceClause?.inheritedTypes else {
            // protocol doesn't has any special conformances
            return ""
        }
        
        var conformancesCode = ": "
        conformanceTypes.forEach { type in
            conformancesCode += "\(type.type), "
        }
        conformancesCode.removeLast(3)
        return TokenSyntax(stringLiteral: conformancesCode)
    }
    
    /// creates the enum definition of all Types with its type as parameter
    private static func enumCasesDefinition(with listOfTypes: [String]) -> TokenSyntax {
        var enums = ""
        for typeName in listOfTypes {
            enums += "case \(enumName(of: typeName))(\(typeName))\n"
        }
        enums.removeLast()
        return TokenSyntax(stringLiteral: enums)
    }
    
    /// creates the definition of the `value` member, that returns in any enum case the parameter as the protocol type
    private static func protocolVarDefinition(with listOfTypes: [String], as type: TokenSyntax) -> TokenSyntax {
        var definition = "/// the not TypeErased object as protocol type\n"
        definition += "var value: any \(type) {\n"
        definition += "switch self {\ncase"
        for typeName in listOfTypes {
            definition += ".\(enumName(of: typeName))(let model as any \(type)),\n"
        }
        definition.removeLast(2)
        definition += ":\nreturn model\n}\n}"
        return TokenSyntax(stringLiteral: definition)
    }
    
    private static func passthroughMembersDefinitions(from protocolMembers: MemberBlockItemListSyntax) -> TokenSyntax {
        var protocolDefinitions = ""
        for memberItem in protocolMembers {
            protocolDefinitions += passthroughVariableDefinition(from: memberItem)
            protocolDefinitions += passthroughFunctionDefinition(from: memberItem)
        }
        if protocolDefinitions.count > 0 {
            protocolDefinitions.removeLast()
        }
        return TokenSyntax(stringLiteral: protocolDefinitions)
    }
    /// Creates a Definition of a computed variable with the same name as in the protocol, that just passes through the variable from all the enum values
    private static func passthroughVariableDefinition(from item: MemberBlockItemListSyntax.Element) -> String {
        if let variableDecl = item.decl.as(VariableDeclSyntax.self) {
            if let binding = variableDecl.bindings.first {
                return "var \(binding.pattern)\(binding.typeAnnotation?.description ?? ""){ self.value.\(binding.pattern) }\n"
            }
        }
        return ""
    }
    
    /// Creates a Definition of a function with the same name as in the protocol, that just passes through the function from all the enum values
    private static func passthroughFunctionDefinition(from item: MemberBlockItemListSyntax.Element) -> String {
        if let functionDecl = item.decl.as(FunctionDeclSyntax.self) {
            var passthroughParameters = ""
            for parameter in functionDecl.signature.parameterClause.parameters {
                passthroughParameters += "\(parameter.firstName): \(parameter.firstName),"
            }
            if passthroughParameters.count > 0 {
                passthroughParameters.removeLast()
            }
            return "\(functionDecl.trimmed) { self.value.\(functionDecl.name)(\(passthroughParameters)) }\n"
        }
        return ""
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
