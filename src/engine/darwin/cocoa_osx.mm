// I don't use objective-c anymore
// preserved just in case

#include <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CFDate.h>
#include <objc/NSObject.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Foundation/Foundation.h>
#include <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <CoreVideo/CVDisplayLink.h>
#import <MetalKit/MetalKit.h>

// __attribute__((constructor))
// static void enableMetalValidation (void)
// {
//     setenv("MTL_DEBUG_LAYER", "1", 1);
//     setenv("MTL_DEBUG_LAYER_ERROR_MODE", "nslog", 1);
//     setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);
//     setenv("MTL_DEBUG_LAYER_VALIDATE_UNRETAINED_RESOURCES", "1", 1);
//     // setenv("MTL_SHADER_VALIDATION", "1", 1);
//     // setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 1);

//     setenv("MTL_HUD_ENABLED", "1", 1);
//     // // setenv("MTL_HUD_LOG_ENABLED", "1", 1);
// }

extern "C"
{
    // functions that are called from obj-c side
    // they all implemented in main.zig

    void init ();
    void update ();
    void draw ();
}

// TODO MetalView and extern Metal functions should be in a separate file
@interface MetalView : NSObject
{
    CGSize frameSize;

    // TODO add CVDisplayLink to support mac os before 10.14
    CADisplayLink *caDisplayLink;
}

@property (readonly) id<MTLDevice> mtDevice;
@property (readonly) CAMetalLayer* mtLayer;
@property (readonly) id<MTLCommandQueue> mtCommandQueue;

- (instancetype)initWithWindow:(NSWindow *)window;
- (void) startDisplayLink;
- (bool) resizeWithWindow:(NSWindow *)window;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate> @end
@interface WindowDelegate : NSObject <NSWindowDelegate> @end

// static makes it accessible only inside this file
// TODO add support for multiple windows and views: use arrays
static NSWindow* _window;
static MetalView* _metalView;

// for simplicity, I won't implement deallocation. Every loaded shader remains forever.
static NSMutableArray<id<MTLLibrary>>* _mtLibraries = [NSMutableArray arrayWithCapacity:64]; // loaded metal shader file
static NSMutableArray<id<MTLRenderPipelineState>>* _mtPipelines = [NSMutableArray arrayWithCapacity:64]; // program with vert and frag

void displayLinkUpdateLoop (MetalView* view)
{
    bool needRedraw = [_metalView resizeWithWindow:_window]; // probably bool is not needed

    update();

    @autoreleasepool // is this ok?
    {
        // nextDrawable may block execution, good idea is to make it non blocking for non rendering update
        id<CAMetalDrawable> drawable = [view.mtLayer nextDrawable];
        if (!drawable) return;

        // NSLog(@"%d", [_MetalLayer nextDrawable] != nil);
        // NSLog(@"x %f", _MetalLayer.drawableSize.width);

        // 1 MTLCommandBuffer per thread
        id<MTLCommandBuffer> commandBuffer = [view.mtCommandQueue commandBuffer]; // commandBufferWithDescriptor, commandBufferWithUnretainedReferences

            // TODO for simplicity at first, I will call draw inside commandBuffer
            // draw();

            MTLRenderPassDescriptor* passDesc = [MTLRenderPassDescriptor renderPassDescriptor];
            passDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;//MTLLoadActionClear; // MTLLoadActionDontCare
            passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
            // passDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
            passDesc.colorAttachments[0].texture = drawable.texture;
            id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDesc];
                // [encoder setViewport:(MTLViewport){0.0, 0.0, drawable.texture.width, drawable.texture.height, 0.0, 1.0 }];
                if (_mtPipelines.count > 0)
                {
                    [encoder setRenderPipelineState:_mtPipelines[0]];
                    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
                    // [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
                }
            [encoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];

        // buffer.waitUntilScheduled
        // [drawable present];
    }
}

extern "C"
{
    // functions that are called from zig side

    void initAndOpenWindow_osx ()
    {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        @autoreleasepool
        {
            NSApplication* app = [NSApplication sharedApplication];
            [app setActivationPolicy:NSApplicationActivationPolicyRegular];
            [app setDelegate:[[AppDelegate alloc] init]];

            NSRect frame = NSMakeRect(0, 0, 690, 690);
            NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;

            _window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:style
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];

            [_window setTitle:@"fluid"];
            [_window setLevel:NSFloatingWindowLevel];
            [_window makeKeyAndOrderFront:nil];
            [_window center];
            [_window setDelegate:[[WindowDelegate alloc] init]];

            // _window.allowsConcurrentViewDrawing = NO;

            _metalView = [[MetalView alloc] initWithWindow:_window];

            [app run]; // runModalForWindow beginModalSessionForWindow
        }

        // [pool drain];
    }

    int32_t createLibraryFromData_metal (const void* data_ptr, size_t data_len)
    {
        // NSString *shaderSource = @"#include <metal_stdlib>\n"
        //                      "using namespace metal;\n"
        //                      "vertex float4 vertexShader(uint vid [[vertex_id]]) {\n"
        //                         "float2 positions[4] = {\n"
        //                             "float2(-1.0, -1.0), // Bottom-left\n"
        //                             "float2( 1.0, -1.0), // Bottom-right\n"
        //                             "float2(-1.0,  1.0), // Top-left\n"
        //                             "float2( 1.0,  1.0)  // Top-right\n"
        //                         "};\n"
        //                         "return float4(positions[vid], 0.0, 1.0);\n"
        //                      "}\n"
        //                      "fragment float4 fragmentShader() {\n"
        //                      "    return float4(0.0, 1.0, 0.0, 1.0);\n"
        //                      "}";

        // id <MTLLibrary> library = [_MetalDevice newLibraryWithSource:shaderSource options:nil error:&errors];
        // id<MTLLibrary> library = [_MetalDevice newLibraryWithURL:[NSURL URLWithString:@"zig-out/metal/shader.metallib"] error:&errors];

        NSError *err = nil;
        dispatch_data_t dispatch_data = dispatch_data_create(data_ptr, data_len, nil, nil); // dispatch_get_main_queue
        id<MTLLibrary> library = [_metalView.mtDevice newLibraryWithData:dispatch_data error:&err];

        // [dispatch_data release]; // TODO check this
        // [library release];

        if (err)
        {
            NSLog(@"%@", err);
            return -1;
        }

        [_mtLibraries addObject:library];
        return _mtLibraries.count - 1;
    }

    int32_t createPipelineVertFrag_metal (int32_t library_idx)
    {
        id<MTLLibrary> library = _mtLibraries[library_idx];

        id<MTLFunction> vertFunc = [library newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragFunc = [library newFunctionWithName:@"fragmentShader"];

        MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
        desc.label = @"Simple Pipeline";
        desc.vertexFunction = vertFunc;
        desc.fragmentFunction = fragFunc;
        desc.vertexDescriptor = nil;
        desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//currentTexture.pixelFormat;

        NSError *err = nil;
        id<MTLRenderPipelineState> _renderPipeline = [_metalView.mtDevice newRenderPipelineStateWithDescriptor:desc error:&err];

        if (err)
        {
            NSLog(@"%@", err);
            return -1;
        }

        [_mtPipelines addObject:_renderPipeline];
        return _mtPipelines.count - 1;
    }
}

// static double _prevFrameTime;

@implementation MetalView
    - (instancetype) initWithWindow:(NSWindow *)window
    {
        _mtLayer = [CAMetalLayer layer];
        _mtDevice = MTLCreateSystemDefaultDevice();
        _mtCommandQueue = [_mtDevice newCommandQueueWithMaxCommandBufferCount: 64];

        _mtLayer.device = _mtDevice;
        _mtLayer.pixelFormat = MTLPixelFormatBGRA8Unorm; // MTLPixelFormatRGBA8Unorm  // MTLPixelFormatBGRA8Unorm_sRGB; MTLPixelFormatRGBA16Float or MTLPixelFormatRGB10A2Unorm for HDR and wide gamut
        _mtLayer.colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB); // nil, kCGColorSpaceGenericRGB
        _mtLayer.opaque = YES;
        _mtLayer.framebufferOnly = YES;
        // kCGColorSpaceExtendedLinearSRGB or kCGColorSpaceExtendedSRGB for wide color; kCGColorSpaceDisplayP3, kCGColorSpaceExtendedLinearDisplayP3
        // _mtLayer.autoresizingMask
        // _mtLayer.developerHUDProperties = @{ @"showGPUStats": @"YES" };

        // TODO play with these values
        // _mtLayer.maximumDrawableCount = 2; // default is 3
        // _mtLayer.allowsNextDrawableTimeout = false;
        // _mtLayer.presentsWithTransaction = true;
        // _mtLayer.displaySyncEnabled = false;

        window.contentView.wantsLayer = YES;
        window.contentView.layer = _mtLayer;

        // TODO play with it
        // window.contentView.layerContentsRedrawPolicy
        // window.contentView.needsDisplay
        // window.contentView.makeBackingLayer
        // window.contentView.

        // NSLog(@"%@",_Window.deviceDescription);
        // NSLog(@"%f", _MetalLayer.maximumDrawableCount);

        // not available on mac os
        // displayLink = [_Window displayLinkWithTarget:() selector:(nonnull SEL)]
        // displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector(repaintDisplayLink)];

        caDisplayLink = [window.screen displayLinkWithTarget:self selector:@selector(displayLinkUpdate:)];
        return self;
    }

    - (void) startDisplayLink
    {
        [caDisplayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes]; // mainRunLoop, currentRunLoop; NSDefaultRunLoopMode, NSRunLoopCommonModes
    }

    - (void) displayLinkUpdate:(CADisplayLink *)link
    {
        double currTime = CACurrentMediaTime();
        // double deltaTime = currTime - _prevFrameTime;
        // _prevFrameTime = currTime;

        double workingTime = link.targetTimestamp - currTime; // this is a correct deltaTime

        // NSLog(@"%f", deltaTime);
        // NSLog(@"%f", workingTime);
        // NSLog(@"%f", link.duration); // super stable but not right for deltaTime
        // NSLog(@"%f", 1 / link.duration); // framerate

        displayLinkUpdateLoop(self);
    }

    - (bool) resizeWithWindow:(NSWindow*) window
    {
        CGSize newSize = window.frame.size;

        if ((int)newSize.width == frameSize.width && (int)newSize.height == frameSize.height)
            return false;

        frameSize = newSize;

        float scale = window.backingScaleFactor; // _Window.screen.backingScaleFactor
        // _MetalLayer.frame = _Window.contentView.bounds;
        _mtLayer.drawableSize = CGSizeMake(newSize.width * scale, newSize.height * scale);
        _mtLayer.contentsScale = window.backingScaleFactor;

        // NSLog(@"%f", _MetalLayer.drawableSize.width);

        return true;
    }
@end

@implementation WindowDelegate
    - (BOOL) windowShouldClose:(NSWindow *)sender { return YES; }

    - (void) windowDidResize:(NSNotification *)notification
    {
        // TODO force render on window resize

        // NSWindow* w = notification.object;
        // NSSize newSize = w.contentView.frame.size;

        // NSLog(@"%s", "windowDidResize");
    }
@end

@implementation AppDelegate
    - (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }

    - (void) applicationDidFinishLaunching:(NSNotification *)notification
    {
        init();

        // TODO is it the perfect place to call it?
        [_metalView startDisplayLink];
    }
@end