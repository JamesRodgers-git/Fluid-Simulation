import Foundation
import Cocoa
import Metal
import Bridge

func enableMetalValidation ()
{
    setenv("MTL_DEBUG_LAYER", "1", 1)
    setenv("MTL_DEBUG_LAYER_ERROR_MODE", "nslog", 1)
    setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1)
    setenv("MTL_DEBUG_LAYER_VALIDATE_UNRETAINED_RESOURCES", "1", 1)
    // setenv("MTL_SHADER_VALIDATION", "1", 1)
    // setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 1)
    setenv("MTL_HUD_ENABLED", "1", 1)
    // setenv("MTL_HUD_LOG_ENABLED", "1", 1)
}

var application: App?
var window: Window?
var metal: MetalView?

// public typealias VoidFunction = @convention(c) () -> Void
// var initFnPtr: VoidFunction?

// main()
// func main ()
// {
//     start_osx()
// }

@_cdecl("start_osx")
public func start_osx ()//(_ initFn: VoidFunction)
{
    enableMetalValidation()

    // print(TEST)

    // initFnPtr = initFn

    let app = NSApplication.shared
    app.setActivationPolicy(.regular)

    application = App(app)
    window = Window()
    metal = MetalView(window!.nswindow)

    app.run()
}

// @available(macOS 14.0, *)
class MetalView
{
    let window: NSWindow

    let device: MTLDevice
    let layer: CAMetalLayer
    let commandQueue: MTLCommandQueue

    private var frameSize: CGSize = .zero
    private var caDisplayLink: CADisplayLink?

    init (_ window: NSWindow)
    {
        self.window = window
        device = MTLCreateSystemDefaultDevice()!
        layer = CAMetalLayer()
        commandQueue = device.makeCommandQueue(maxCommandBufferCount: 64)!

        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        layer.isOpaque = true
        layer.framebufferOnly = true

        window.contentView?.wantsLayer = true
        window.contentView?.layer = layer

        caDisplayLink = window.screen?.displayLink(target: self, selector: #selector(displayLinkUpdate))
    }

    deinit
    {
        guard let caDisplayLink = caDisplayLink else { return }
        caDisplayLink.invalidate();
    }

    public func startDisplayLink ()
    {
        caDisplayLink?.add(to: .current, forMode: .common)
    }

    @objc func displayLinkUpdate (_ link: CADisplayLink)
    {
        // let currTime = CACurrentMediaTime()
        // let workingTime = link.targetTimestamp - currTime
        displayLinkUpdateLoop()
    }

    func displayLinkUpdateLoop ()
    {
        // let needRedraw = resize()
        let _ = resize()
        // update()
        autoreleasepool
        {
            guard let drawable = layer.nextDrawable() else { return }

            let commandBuffer = commandQueue.makeCommandBuffer()!

            let passDesc = MTLRenderPassDescriptor()
            passDesc.colorAttachments[0].loadAction = .clear
            passDesc.colorAttachments[0].storeAction = .store
            passDesc.colorAttachments[0].texture = drawable.texture
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDesc)!
            // {
                if !_mtPipelines.isEmpty
                {
                    encoder.setRenderPipelineState(_mtPipelines[0])
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                }
            // }
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    func resize () -> Bool
    {
        let newSize = window.frame.size

        if Int(newSize.width) == Int(frameSize.width) && Int(newSize.height) == Int(frameSize.height)
        {
            return false
        }

        frameSize = newSize

        let scale = window.backingScaleFactor
        layer.drawableSize = CGSize(width: newSize.width * scale, height: newSize.height * scale)
        layer.contentsScale = scale

        return true
    }
}

class App: NSObject, NSApplicationDelegate
{
    init (_ app: NSApplication)
    {
        super.init()

        app.delegate = self
    }

    func applicationShouldTerminateAfterLastWindowClosed (_ sender: NSApplication) -> Bool
    {
        return true
    }

    func applicationDidFinishLaunching (_ notification: Notification)
    {
        start()

        metal!.startDisplayLink()
    }
}

class Window: NSObject, NSWindowDelegate
{
    public var nswindow: NSWindow

    override init ()
    {
        let frame = NSRect(x: 0, y: 0, width: 690, height: 690)
        let style: NSWindow.StyleMask = [.titled, .closable, .resizable]
        nswindow = NSWindow(contentRect: frame, styleMask: style, backing: .buffered, defer: false)

        super.init()

        nswindow.title = "fluid"
        nswindow.level = .floating
        nswindow.makeKeyAndOrderFront(nil)
        nswindow.center()
        nswindow.delegate = self
    }

    func windowShouldClose (_ sender: NSWindow) -> Bool
    {
        return true
    }

    func windowDidResize (_ notification: Notification)
    {
        // TODO force render on window resize
    }
}
