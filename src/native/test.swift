import Cocoa

// couldn't figure out how to compile swift into library
// that can be used in zig, so I use objective-c instead

// "swiftc",
// "-emit-library",
// "-emit-objc-header",
// "-emit-clang-header-path",
// "-static-stdlib",
// "-static",
// "-o", "test.a", "test.swift"

@_cdecl("test_osx")
public func test ()
{
}