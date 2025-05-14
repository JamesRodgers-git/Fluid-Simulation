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

__attribute__((constructor))
static void enableMetalValidation (void)
{
    setenv("MTL_DEBUG_LAYER", "1", 1);
    setenv("MTL_DEBUG_LAYER_ERROR_MODE", "nslog", 1);
    setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);
    setenv("MTL_DEBUG_LAYER_VALIDATE_UNRETAINED_RESOURCES", "1", 1);
    // setenv("MTL_SHADER_VALIDATION", "1", 1);
    // setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 1);
}

extern "C"
{
// functions that are called from obj-c side
// they all implemented in main.zig

    void init ();
    void update ();
    void draw ();
}

@interface Renderer : NSObject
{
    // TODO add CVDisplayLink to support mac os before 10.14

    CADisplayLink *displayLink;
    // NSWindow *_Window;
}
- (instancetype)init:(NSWindow *)window;
- (void) startDisplayLink;
// - (void)createDisplayLink:(NSWindow *)window;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate> @end
@interface WindowDelegate : NSObject <NSWindowDelegate> @end

// static makes it accessible only inside this file
static CAMetalLayer* _MetalLayer;
static id<MTLDevice> _MetalDevice;
static id<MTLCommandQueue> _MetalCommandQueue;
static id<MTLLibrary> _MetalLibrary;
static Renderer* _Renderer;

static NSWindow* _Window;
static int _WindowWidth;
static int _WindowHeight;

static id<MTLRenderPipelineState> _renderPipeline;

void initMetal ()
{
    _MetalLayer = [CAMetalLayer layer];
    _MetalDevice = MTLCreateSystemDefaultDevice();
    _MetalCommandQueue = [_MetalDevice newCommandQueueWithMaxCommandBufferCount: 64];
    _MetalLibrary = [_MetalDevice newDefaultLibrary];

    _MetalLayer.device = _MetalDevice;
    _MetalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm; // MTLPixelFormatRGBA8Unorm  // MTLPixelFormatBGRA8Unorm_sRGB; MTLPixelFormatRGBA16Float or MTLPixelFormatRGB10A2Unorm for HDR and wide gamut
    _MetalLayer.colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB); // nil, kCGColorSpaceGenericRGB
    _MetalLayer.opaque = YES;
    _MetalLayer.framebufferOnly = YES;
    // kCGColorSpaceExtendedLinearSRGB or kCGColorSpaceExtendedSRGB for wide color; kCGColorSpaceDisplayP3, kCGColorSpaceExtendedLinearDisplayP3
    // _MetalLayer.autoresizingMask

    _Window.contentView.wantsLayer = YES;
    _Window.contentView.layer = _MetalLayer;

    // TODO play with it
    // _Window.contentView.layerContentsRedrawPolicy
    // _Window.contentView.needsDisplay
    // _Window.contentView.makeBackingLayer
    // _Window.contentView.

    // TODO play with these values
    // _MetalLayer.maximumDrawableCount = 2; // default is 3
    // _MetalLayer.allowsNextDrawableTimeout = false;
    // _MetalLayer.presentsWithTransaction = true;
    // _MetalLayer.displaySyncEnabled = false;

    _Renderer = [[Renderer alloc] init:_Window];

    // NSLog(@"%@",_Window.deviceDescription);
    // NSLog(@"%f", _MetalLayer.maximumDrawableCount);

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

    NSError *errors;

    // NSArray *desktopFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"./src/engine/darwin" error:&errors];
    // NSLog(@"count: %d", desktopFiles.count);

    // NSString *shaderSource = [NSString stringWithContentsOfFile:@"src/engine/darwin/shader.metal"
    //                                                       encoding:NSUTF8StringEncoding 
    //                                                          error:&errors];
    // NSLog(@"%@", errors);

    // id <MTLLibrary> library = [_MetalDevice newLibraryWithSource:shaderSource options:nil error:&errors];

    id <MTLLibrary> library = [_MetalDevice newLibraryWithURL:[NSURL URLWithString:@"zig-out/metal/shader.metallib"] error:&errors];
    id <MTLFunction> vertFunc = [library newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragFunc = [library newFunctionWithName:@"fragmentShader"];

    NSLog(@"%@", errors);

    MTLRenderPipelineDescriptor* renderPipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDesc.label = @"Simple Pipeline";
    renderPipelineDesc.vertexFunction = vertFunc;
    renderPipelineDesc.fragmentFunction = fragFunc;
    renderPipelineDesc.vertexDescriptor = nil;
    renderPipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//currentTexture.pixelFormat;
    _renderPipeline = [_MetalDevice newRenderPipelineStateWithDescriptor:renderPipelineDesc error:&errors];
    
    NSLog(@"%@", errors);
}

bool resizeMetal ()
{
    CGSize frameSize = _Window.frame.size;

    if ((int)frameSize.width == _WindowWidth && (int)frameSize.height == _WindowHeight)
        return false;

    _WindowWidth = frameSize.width;
    _WindowHeight = frameSize.height;

    float scale = _Window.backingScaleFactor; // _Window.screen.backingScaleFactor
    // _MetalLayer.frame = _Window.contentView.bounds;
    _MetalLayer.drawableSize = CGSizeMake(frameSize.width * scale, frameSize.height * scale);
    _MetalLayer.contentsScale = _Window.backingScaleFactor;

    // NSLog(@"%f", _MetalLayer.drawableSize.width);

    return true;
}

void displayLinkUpdateLoop ()
{
    bool needRedraw = false; // probably not needed
    if (resizeMetal())
        needRedraw = true;

    update();

    @autoreleasepool // is this ok?
    {
        // nextDrawable may block execution, good idea is to make it non blocking for non rendering update
        id<CAMetalDrawable> drawable = [_MetalLayer nextDrawable];
        if (!drawable) return;

        // NSLog(@"%d", [_MetalLayer nextDrawable] != nil);
        // NSLog(@"x %f", _MetalLayer.drawableSize.width);

        // 1 MTLCommandBuffer is enough for whole application
        id<MTLCommandBuffer> commandBuffer = [_MetalCommandQueue commandBuffer]; // commandBufferWithDescriptor, commandBufferWithUnretainedReferences

            MTLRenderPassDescriptor* passDesc = [MTLRenderPassDescriptor renderPassDescriptor];
            passDesc.colorAttachments[0].loadAction = MTLLoadActionClear; // MTLLoadActionDontCare
            passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
            passDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
            passDesc.colorAttachments[0].texture = drawable.texture;
            id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDesc];
                // [encoder setViewport:(MTLViewport){0.0, 0.0, drawable.texture.width, drawable.texture.height, 0.0, 1.0 }];
                [encoder setRenderPipelineState:_renderPipeline];
                [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
                // [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [encoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];

        // draw();

        // buffer.waitUntilScheduled
        // [drawable present];
    }
}

extern "C"
{
// functions that are called from zig side

    void init_and_open_window_osx ()
    {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        @autoreleasepool
        {
            NSApplication* app = [NSApplication sharedApplication];
            [app setActivationPolicy:NSApplicationActivationPolicyRegular];
            [app setDelegate:[[AppDelegate alloc] init]];

            NSRect frame = NSMakeRect(0, 0, 690, 690);
            NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;

            _Window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:style
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];

            [_Window setTitle:@"fluid"];
            [_Window setLevel:NSFloatingWindowLevel];
            [_Window makeKeyAndOrderFront:nil];
            [_Window center];
            [_Window setDelegate:[[WindowDelegate alloc] init]];

            // _Window.allowsConcurrentViewDrawing = NO;

            initMetal();

            [app run]; // runModalForWindow beginModalSessionForWindow
        }

        // [pool drain];
    }
}

static double _prevFrameTime;

@implementation Renderer
    - (instancetype) init:(NSWindow *)window
    {
        // not available on mac os
        // displayLink = [_Window displayLinkWithTarget:() selector:(nonnull SEL)]
        // displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector(repaintDisplayLink)];

        displayLink = [window.screen displayLinkWithTarget:self selector:@selector(displayLinkUpdate:)];
        return self;
    }

    - (void) startDisplayLink
    {
        [displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes]; // mainRunLoop, currentRunLoop; NSDefaultRunLoopMode, NSRunLoopCommonModes
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

        displayLinkUpdateLoop();
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
        [_Renderer startDisplayLink];
    }
@end