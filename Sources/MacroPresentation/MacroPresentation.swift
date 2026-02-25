// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroPresentationMacros", type: "StringifyMacro")

@attached(member, names: named(title))
public macro EnumTitle() = #externalMacro(module: "MacroPresentationMacros", type: "EnumTitleMacro")


@attached(member, names: named(CodingKeys))
public macro EnumCodingKeys() = #externalMacro(module: "MacroPresentationMacros", type: "EnumCodingKeysMacro")
