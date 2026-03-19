import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

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
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
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
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw EnumInitError.enumCodingKeysError
        }
        
        guard let memberBlock = declaration.memberBlock.as(MemberBlockSyntax.self) else {
            throw EnumInitError.enumCodingKeysError
        }
        
        let style = node.arguments?.as(LabeledExprListSyntax.self)?
                .first(where: { $0.label?.text == "style" })?
                .expression.as(MemberAccessExprSyntax.self)?
                .declName.baseName.text ?? "snakeCase"
        
        let cases = memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { variables in
                let isStatic = variables.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
                let isComputed = variables.bindings.allSatisfy { $0.accessorBlock != nil }
                return !isStatic && !isComputed
            }.flatMap { $0.bindings }
            .compactMap { binding -> String? in
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    return nil
                }
                let rawValue: String
                
                switch style {
                case "snakeCase":
                    rawValue = identifier.processSnakeCase
                case "pascalCase":
                    rawValue = identifier.prefix(1).uppercased() + identifier.dropFirst()
                case "camelCase":
                    rawValue = identifier
                default:
                    rawValue = identifier
                }
                        
                return "case \(identifier) = \"\(rawValue)\""
            }
      
        if cases.isEmpty { return [] }
        
        let enumCodingKeys: DeclSyntax = """
        enum CodingKeys: String, CodingKey {
            \(raw: cases.joined(separator: "\n    "))
        }
        """
        
       return [enumCodingKeys]
    }
}

public enum EnumInitError: CustomStringConvertible, Error {
    case onlyApplicableToEnum
    case enumCodingKeysError
    public var description: String {
        switch self {
        case .onlyApplicableToEnum:
            return "@EnumTitle macro can only be applied to an enum"
        case .enumCodingKeysError:
            return "@EnumCodingKeys macro can only be applied to a struct or a class"
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

extension String {
    var processSnakeCase: String {
        let snake = unicodeScalars.reduce("") { res, char in
            if CharacterSet.uppercaseLetters.contains(char) && !res.isEmpty {
                return res + "_" + String(char)
            }
            return res + String(char)
        }
        return snake.lowercased()
    }
}
