//
//  ABConfig.swift
//
//
//  Created by Mustafa Alp on 16.06.2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

enum ABConfigMacroErrors: CustomStringConvertible, Error {
    case appliableToDecl(String, String)
    case missingParameter
    case dimensionRequired
    case mustBeStructInside
    case mustBeABConfigDefinedStruct(String)

    var description: String {
        switch self {
        case .mustBeStructInside:
            return "@ABConfigurable works if all the inner declaration is struct"
        case .appliableToDecl(let macro, let declaration):
            return "\(macro) can only be applied to \(declaration)"
        case .missingParameter:
            return "@ABConfig should have at least 1 argument"
        case .dimensionRequired:
            return "@ABConfig requires dimension to be not nil or empty. Please check your 'firebaseDimension' parameter"
        case .mustBeABConfigDefinedStruct(let structName):
            return "You need to define inner structs using @ABConfig macro. Check your '\(structName)' struct definition"
        }
    }
}

public struct ABConfig: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw ABConfigMacroErrors.appliableToDecl("@ABConfig", "structs")
        }

        guard case let .argumentList(argumentList) = node.argument,
              argumentList.count == 1,
              let funcExpr = argumentList.first?.expression.as(FunctionCallExprSyntax.self)
        else {
            throw ABConfigMacroErrors.missingParameter
        }

        var parameterDict = [String: ExprSyntax]()
        funcExpr.argumentList.forEach {
            if let label = $0.label?.text,
               let expression = $0.expression.as(ExprSyntax.self) {
                parameterDict[label] = expression
            }
        }

        var decls: [DeclSyntax] = [DeclSyntax("public init() { }")]

        guard let dimension = getStringValue(parameterDict, key: "firebaseDimension"),
              dimension.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
        else {
            throw ABConfigMacroErrors.dimensionRequired
        }

        decls.append(DeclSyntax(
                """
                public var firebaseDimension: String { "\(raw: dimension)" }
                """
            )
        )

        if let legacy = getBoolValue(parameterDict, key: "isLegacyConfig") {
            decls.append(DeclSyntax(
                    """
                    public var isLegacyConfig: Bool { \(raw: legacy) }
                    """
                )
            )
        }

        if let commonConfig = getBoolValue(parameterDict, key: "isCommonConfig") {
            decls.append(DeclSyntax(
                    """
                    public var isCommonConfig: Bool { \(raw: commonConfig) }
                    """
                )
            )
        }

        if let name = getStringValue(parameterDict, key: "name") {
            decls.append(DeclSyntax(
                    """
                    public var name: String { "\(raw: name)" }
                    """
                )
            )
        }

        return decls
    }

    private static func getStringValue(_ dict: [String: ExprSyntax], key: String) -> String? {
        guard let param = dict[key],
              let paramLiteral = param.as(StringLiteralExprSyntax.self),
              paramLiteral.segments.count == 1,
              case let .stringSegment(textVal)? = paramLiteral.segments.first
        else { return nil }

        return textVal.content.text
    }

    private static func getBoolValue(_ dict: [String: ExprSyntax], key: String, defaultValue: Bool = false) -> String? {
        guard let param = dict[key],
              let token = param.as(BooleanLiteralExprSyntax.self)
        else { return defaultValue ? "true" : "false" }

        return token.booleanLiteral.text
    }
}

extension ABConfig: ConformanceMacro {
    private static let typeName: String = "ABConfigurable"
    private static var conformanceType: TypeSyntax {
        "\(raw: typeName)"
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        if let structDecl = declaration.as(StructDeclSyntax.self),
           let inheritedTypes = structDecl.inheritanceClause?.inheritedTypeCollection,
           inheritedTypes.contains(where: { inherited in inherited.typeName.trimmedDescription == typeName }) {
            return []
        }

        return [(conformanceType, nil)]
    }
}
