import Cocoa
import Fluid

// couldn't figure out how to link swift's system libraries into zig compile step
// so I use objective-c instead

// bridge.h and module.modulemap is part of this swift code

// "xcrun", "swiftc",
// "-emit-object",
// "-I", "src/engine/darwin/",
// "-o", "zig-out/lib/test.o",
// "src/engine/darwin/test.swift"

@_cdecl("swift_test")
public func swift_test ()
{
    // print("hi");
    update();
}