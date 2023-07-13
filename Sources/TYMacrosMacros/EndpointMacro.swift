//
//  EndpointMacro.swift
//
//
//  Created by Mustafa Alp on 12.06.2023.
//

import SwiftSyntax
import SwiftSyntaxMacros

enum EndpointMacroErrors: CustomStringConvertible, Error {
    case appliableToEnum
    case missingParameter
    case readingParameter
    case requireAllCases
    case wrongCase(String)

    var description: String {
        switch self {
        case .appliableToEnum:
            return "@Endpoint can only be applied to enums"
        case .missingParameter:
            return "@Endpoint should have at least 1 argument"
        case .readingParameter:
            return "@Endpoint can work with static parameters for now"
        case .requireAllCases:
            return "@Endpoint arguments does not match enum cases. Add arguments for missing cases"
        case .wrongCase(let param):
            return "This enum does not have case named: '\(param)'"
        }
    }
}

public struct EndpointMacro: ConformanceMacro {
    private static var conformanceType: TypeSyntax {
        "\(raw: "Endpoint")"
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        let inheritanceList: InheritedTypeListSyntax?
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            inheritanceList = classDecl.inheritanceClause?.inheritedTypeCollection
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            inheritanceList = structDecl.inheritanceClause?.inheritedTypeCollection
        } else {
            inheritanceList = nil
        }

        if let inheritanceList {
            for inheritance in inheritanceList {
                if inheritance.typeName == conformanceType {
                    return []
                }
            }
        }

        return [("Endpoint", nil)]
    }
}

extension EndpointMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context) throws -> [SwiftSyntax.DeclSyntax] where Declaration : SwiftSyntax.DeclGroupSyntax, Context : SwiftSyntaxMacros.MacroExpansionContext {
            guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
                throw EndpointMacroErrors.appliableToEnum
            }

            guard case let .argumentList(argumentList) = node.argument,
                  argumentList.count == 1,
                  let arrExpr = argumentList.first?.expression.as(ArrayExprSyntax.self)
            else {
                throw EndpointMacroErrors.missingParameter
            }

            var paths = [String]()
            var baseUrls = [String]()

            let members = enumDecl.memberBlock.members
            let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            let elements = caseDecls.flatMap { $0.elements }
            let declCases = elements.map { $0.identifier.text }

            guard elements.count == arrExpr.elements.count
            else {
                throw EndpointMacroErrors.requireAllCases
            }

            try arrExpr.elements.forEach {
                guard let functionCall = $0.expression.as(FunctionCallExprSyntax.self) else { return }
                var parameterDict = [String: ExprSyntax]()
                functionCall.argumentList.forEach {
                    if let label = $0.label?.text,
                       let expression = $0.expression.as(ExprSyntax.self) {
                        parameterDict[label] = expression
                    }
                }

                guard let caseName = getStringValue(parameterDict, key: "caseName"),
                      let baseUrl = getStringValue(parameterDict, key: "baseUrl"),
                      let path = getStringValue(parameterDict, key: "path")
                else { return }

                if !declCases.contains(caseName) {
                    throw EndpointMacroErrors.wrongCase(caseName)
                }

                paths.append(
                    """
                    case .\(caseName):
                    return \(addDoubleQuoteIfNeeded(for: path))
                    """
                )

                baseUrls.append(
                    """
                    case .\(caseName):
                    return \(addDoubleQuoteIfNeeded(for: baseUrl))
                    """
                )
            }

            guard paths.count > 0, baseUrls.count > 0 else {
                throw EndpointMacroErrors.readingParameter
            }

            let pathDecl: DeclSyntax = """


var path: String {
    switch self {
    \(raw: paths.joined(separator: "\n"))
  }
}


"""

            let baseUrlDecl: DeclSyntax = """


var baseUrl: String {
    switch self {
    \(raw: baseUrls.joined(separator: "\n"))
  }
}

"""

            return [
                baseUrlDecl,
                pathDecl
            ]
        }

    private static func getStringValue(_ dict: [String: ExprSyntax], key: String) -> String? {
        guard let param = dict[key],
              let paramLiteral = param.as(StringLiteralExprSyntax.self),
              paramLiteral.segments.count == 1,
              case let .stringSegment(textVal)? = paramLiteral.segments.first
        else { return nil }

        return textVal.content.text
    }

    private static func addDoubleQuoteIfNeeded(for text: String) -> String {
        var newText = text
        if text.hasPrefix("{") && text.hasSuffix("}") {
            newText = String(newText.dropFirst())
            newText = String(newText.dropLast())
            return newText
        }
        return "\"\(text)\""
    }
}
