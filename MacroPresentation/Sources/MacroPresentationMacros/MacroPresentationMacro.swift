import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}


public struct EnumTitleMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw EnumInitError.onlyApplicableToEnum
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecl = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecl.flatMap { $0.elements }
        
        let varSyntax = try VariableDeclSyntax("var title: String")
        let _case = TokenSyntax(stringLiteral: "\(Keyword.case)")
        let _return = TokenSyntax(stringLiteral: "\(Keyword.return)")
        let _switch = TokenSyntax(stringLiteral: "\(Keyword.switch)")
        let _self = TokenSyntax(stringLiteral: "\(Keyword.`self`)")
        
        var title =
        """
        \(varSyntax) {
        """
        let switchExpSyntax = try SwitchExprSyntax("\(_switch) \(_self)") {
            for element in elements {
                SwitchCaseSyntax("\(_case) .\(element.name):") {
                    "\(_return) \"\(element.name)\""
                }
            }
        }
        title += "\(switchExpSyntax)"
        title +=
        """
            }
        """
        return [DeclSyntax(stringLiteral: "\(title)")]
    }
}

public struct EnumCodingKeysMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        guard let declStruct = declaration.as(StructDeclSyntax.self) else {
            throw EnumInitError.onlyApplicableToStruct
        }
        
        let members = declStruct.memberBlock.members
        let variables = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let bindings = variables.flatMap { $0.bindings }
        
        var enumCodingKeys = """
        enum CodingKeys: String, CodingKey {
"""
        for binding in bindings {
            let description = TokenSyntax(stringLiteral: "\(binding.pattern.description)")
            let capitalisedFirst = String(description.text.prefix(1)).uppercased() + String(description.text.dropFirst())
            enumCodingKeys += "\(Keyword.case) \(description) = \"\(capitalisedFirst)\""
        }
        
        enumCodingKeys += "}"
        
       return [DeclSyntax(stringLiteral: "\(enumCodingKeys)")]
    }
}

public enum EnumInitError: CustomStringConvertible, Error {
    case onlyApplicableToEnum
    case onlyApplicableToStruct
    public var description: String {
        switch self {
            case .onlyApplicableToEnum:
                return "@EnumTitle macro can only be applied to an enum"
            case .onlyApplicableToStruct:
                return "@EnumCodingKeys macro can only be applied to a stuct"
        }
    }
}

@main
struct MacroPresentationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        EnumTitleMacro.self,
        EnumCodingKeysMacro.self
    ]
}
