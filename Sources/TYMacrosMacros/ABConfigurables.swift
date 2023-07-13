//
//  ABConfigurables.swift
//
//
//  Created by Mustafa Alp on 26.06.2023.
//

import SwiftSyntax
import SwiftSyntaxMacros

public enum Channel: String {
    case ty
    case meal
    case dolap
    case grocery
    case international

    public var prefix: String {
        switch self {
        case .dolap:
            return "DL"
        case .grocery:
            return "GRC"
        case .international:
            return "INT"
        case .meal:
            return "ML"
        case .ty:
            return "TY"
        }
    }
}

private extension ABConfigurables {
    enum Constant {
        static let abConfigurable = "@ABConfigurable"
        static let abConfig = "ABConfig"
        static let definitionStructName = "ABTestDefinitions"
    }
}

public struct ABConfigurables: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext) throws -> [DeclSyntax] {
            guard let decl = declaration.as(StructDeclSyntax.self) else {
                throw ABConfigMacroErrors.appliableToDecl(Constant.abConfigurable, "structs")
            }

            var channel: Channel = .ty

            if case let .argumentList(arguments) = node.argument,
               let element = arguments.as(TupleExprElementListSyntax.self),
               let expression = element.first?.expression.as(MemberAccessExprSyntax.self),
               let channelEnum = Channel(rawValue: expression.name.text) {
                channel = channelEnum
            }

            var abList = [String]()
            for member in decl.memberBlock.members {
                guard let memberItem = member.as(MemberDeclListItemSyntax.self)
                else { return [] }

                if !memberItem.decl.is(InitializerDeclSyntax.self) {
                    guard let memberDecl = memberItem.decl.as(StructDeclSyntax.self)
                    else { throw ABConfigMacroErrors.mustBeStructInside }

                    guard case let .attribute(attribute) = memberDecl.attributes?.first,
                          let identifier = attribute.attributeName.as(SimpleTypeIdentifierSyntax.self),
                          identifier.name.text == Constant.abConfig
                    else { throw ABConfigMacroErrors.mustBeABConfigDefinedStruct(memberDecl.identifier.text) }

                    abList.append("\(Constant.definitionStructName).\(memberDecl.identifier.text)()")
                }
            }

            let declSyntax = DeclSyntax(
                """
                public struct \(raw: channel.prefix)ABTests {
                    public init() {}

                    public var tests: [ABConfigurable] = [
                        \(raw: abList.joined(separator: ",\n"))
                    ]
                }
                """
            )

            return [declSyntax]
    }
}
