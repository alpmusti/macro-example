//
//  File.swift
//  
//
//  Created by Mustafa Alp on 12.06.2023.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TYMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EndpointMacro.self,
        ABConfig.self,
        ABConfigurables.self
    ]
}

