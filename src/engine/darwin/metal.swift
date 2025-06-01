import Foundation
import Cocoa
import Metal
import Bridge
import Graphics

extension UnsafeRawPointer
{
    func toMTLLibrary() -> MTLLibrary { return Unmanaged<MTLLibrary>.fromOpaque(self).takeUnretainedValue() }
    func toMTLFunction() -> MTLFunction { return Unmanaged<MTLFunction>.fromOpaque(self).takeUnretainedValue() }
    // func toMTLDevice() -> MTLDevice { return Unmanaged<MTLDevice>.fromOpaque(self).takeUnretainedValue() }
}

// TODO remove
var _mtPipelines: [MTLRenderPipelineState] = [] // pipeline is a combo of vert+frag functions, +blend and etc.. (Material)

@_cdecl("createLibraryFromData_metal")
public func createLibraryFromData_metal (data_ptr: UnsafeRawPointer, data_len: Int) -> UnsafeMutableRawPointer?
{
    let data = DispatchData(bytesNoCopy: UnsafeRawBufferPointer(start: data_ptr, count: data_len))//, deallocator: .custom(nil, nil))

    do
    {
        let library = try metal!.device.makeLibrary(data: data)
        return Unmanaged.passRetained(library).toOpaque()
    }
    catch
    {
        print(error)
        return nil
    }
}

@_cdecl("createFunction_metal")
public func createFunction_metal (name: UnsafePointer<CChar>, library: UnsafeRawPointer) -> UnsafeMutableRawPointer?
{
    let name = String(cString: name)
    let library = library.toMTLLibrary()

    let desc = MTLFunctionDescriptor()
    desc.name = name

    // let constantValues = MTLFunctionConstantValues();
    // constantValues.set
    // desc.constantValues = constantValues

    do
    {
        let function = try library.makeFunction(descriptor: desc)
        return Unmanaged.passRetained(function).toOpaque()
    }
    catch
    {
        print(error);
        return nil
    }

    // guard let function = library.makeFunction(name: name) else { return nil }
    // return Unmanaged.passRetained(function).toOpaque()
}

@_cdecl("createPipelineVertFrag_metal")
public func createPipelineVertFrag_metal (name: UnsafePointer<CChar>,
                                          vert: UnsafeRawPointer,
                                          frag: UnsafeRawPointer) -> UnsafeMutableRawPointer?
{
    let name = String(cString: name)
    let vert = vert.toMTLFunction()
    let frag = frag.toMTLFunction()

    let desc = MTLRenderPipelineDescriptor()
    desc.label = name
    desc.vertexFunction = vert
    desc.fragmentFunction = frag
    // desc.vertexDescriptor = nil
    desc.colorAttachments[0].pixelFormat = .bgra8Unorm

    do
    {
        let pipeline = try metal!.device.makeRenderPipelineState(descriptor: desc)
        _mtPipelines.append(pipeline)
        return Unmanaged.passRetained(pipeline).toOpaque()
    }
    catch
    {
        print(error)
        return nil
    }
}