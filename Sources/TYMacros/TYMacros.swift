// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
//@freestanding(expression)
//public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "TYMacrosMacros", type: "StringifyMacro")

import TYMacrosMacros

public enum HTTPMethod: String {
    case get = "GET"
}

public struct EndpointArguments {
    public let caseName: String
    public let baseUrl: String
    public let path: String
    public let method: HTTPMethod
    public var headers: [String: String] = [:]
    public var params: [String: Any]? = nil

    public init(caseName: String, baseUrl: String, path: String, method: HTTPMethod = .get, headers: [String: String] = [:], params: [String : Any]? = nil) {
        self.caseName = caseName
        self.baseUrl = baseUrl
        self.path = path
        self.method = method
        self.headers = headers
        self.params = params
    }
}

public protocol Endpoint {
    var path: String { get }
    var baseUrl: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var params: [String: Any]? { get }
}

public extension Endpoint {
    var method: HTTPMethod { .get }
    var params: [String: Any]? { nil }
    var headers: [String: String] { [:] }
}

@attached(member, names: named(path), named(baseUrl))
@attached(conformance)
public macro EndpointMacro(args: [EndpointArguments]) -> () = #externalMacro(module: "TYMacrosMacros", type: "EndpointMacro")

public protocol ABConfigurable {
    var isLegacyConfig: Bool { get }
    var firebaseDimension: String { get }
}

public struct ABConfigArguments {
    public let firebaseDimension: String
    public let isLegacyConfig: Bool
    public let isCommonConfig: Bool
    public let name: String

    public init(firebaseDimension: String, isLegacyConfig: Bool = false, name: String = "", isCommonConfig: Bool = false) {
        self.isLegacyConfig = isLegacyConfig
        self.firebaseDimension = firebaseDimension
        self.name = name
        self.isCommonConfig = isCommonConfig
    }
}

@attached(conformance)
@attached(member, names: named(init), named(isLegacyConfig), named(isCommonConfig), named(firebaseDimension))
public macro ABConfig(args: ABConfigArguments) -> () = #externalMacro(module: "TYMacrosMacros", type: "ABConfig")

@attached(peer, names: named(TYABTests), named(MLABTests), named(GRCABTests), named(DLABTests), named(INTABTests))
public macro ABConfigurables(channel: Channel = .ty) -> () = #externalMacro(module: "TYMacrosMacros", type: "ABConfigurables")
