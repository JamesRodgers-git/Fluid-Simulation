#import <Cocoa/Cocoa.h>
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

// static makes it accessible only inside this file
static NSWindow *_Window;
static CAMetalLayer *_MetalLayer;
static id<MTLDevice> _MetalDevice;
static id<MTLCommandQueue> _MetalCommandQueue;
static CAMetalDisplayLink *_MetalDisplayLink; // minimum iOS 17, better use CADisplayLink and CVDisplayLink

@interface MetalDisplayLinkDelegate : NSObject <CAMetalDisplayLinkDelegate> @end
@implementation MetalDisplayLinkDelegate

    // Apple wtf is this syntax
    - (void) metalDisplayLink:(nonnull CAMetalDisplayLink *)link needsUpdate:(nonnull CAMetalDisplayLinkUpdate *)update
    {
        // NSLog(@"x %f", _MetalLayer.contentsScale);

        // NSLog(@"%d", update.drawable != nil);
        // update.drawable

        @autoreleasepool
        {
            // id<CAMetalDrawable> drawable = update.drawable;
            id<CAMetalDrawable> drawable = [_MetalLayer nextDrawable]; // wtf nextDrawable returns nil
            if (!drawable) return;

            // NSLog(@"%d", [_MetalLayer nextDrawable] != nil);
            // NSLog(@"x %f", _MetalLayer.drawableSize.width);

            MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
            pass.colorAttachments[0].loadAction = MTLLoadActionClear; // MTLLoadActionDontCare
            pass.colorAttachments[0].storeAction = MTLStoreActionStore;
            pass.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
            pass.colorAttachments[0].texture = drawable.texture;

            // id<MTLCommandQueue> commandQueue = [_MetalLayer.device newCommandQueue];
            id<MTLCommandBuffer> buffer = [_MetalCommandQueue commandBuffer];

            id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
            [encoder endEncoding];

            [buffer presentDrawable:drawable];
            [buffer commit];

            // buffer.waitUntilScheduled
            // [drawable present];
        }
    }

@end

@interface AppDelegate : NSObject <NSApplicationDelegate> @end
@implementation AppDelegate

    - (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }

    - (void) applicationDidFinishLaunching:(NSNotification *)notification
    {
        _MetalLayer = [CAMetalLayer layer];
        _MetalDevice = MTLCreateSystemDefaultDevice();
        _MetalCommandQueue = [_MetalDevice newCommandQueueWithMaxCommandBufferCount: 64];

        _MetalLayer.device = _MetalDevice;
        _MetalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm; // MTLPixelFormatBGRA8Unorm_sRGB; MTLPixelFormatRGBA16Float or MTLPixelFormatRGB10A2Unorm for HDR and wide gamut
        _MetalLayer.opaque = YES;
        _MetalLayer.framebufferOnly = YES;
        _MetalLayer.colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB); // nil, kCGColorSpaceGenericRGB
        // kCGColorSpaceExtendedLinearSRGB or kCGColorSpaceExtendedSRGB for wide color; kCGColorSpaceDisplayP3, kCGColorSpaceExtendedLinearDisplayP3

        _Window.contentView.wantsLayer = YES;
        _Window.contentView.layer = _MetalLayer;

        // TODO check this
        // _Window.contentView.layerContentsRedrawPolicy
        // _Window.contentView.needsDisplay
        // _Window.contentView.makeBackingLayer
        // _Window.contentView.

        // _MetalLayer.frame = _Window.contentView.bounds;
        _MetalLayer.drawableSize = CGSizeMake(690 * _Window.backingScaleFactor, 690 * _Window.backingScaleFactor);
        _MetalLayer.contentsScale = _Window.backingScaleFactor;

        // TODO play with these values
        // _MetalLayer.maximumDrawableCount = 2;
        // _MetalLayer.allowsNextDrawableTimeout = false;
        // _MetalLayer.presentsWithTransaction = true;
        // _MetalLayer.displaySyncEnabled = false;
        // _MetalLayer.maximumDrawableCount = 2;

        _MetalDisplayLink = [[CAMetalDisplayLink alloc] initWithMetalLayer:_MetalLayer];
        // _MetalDisplayLink.preferredFrameRateRange = 
        [_MetalDisplayLink setDelegate:[[MetalDisplayLinkDelegate alloc] init]];
        [_MetalDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode]; // currentRunLoop; NSRunLoopCommonModes
    }

@end

@interface WindowDelegate : NSObject <NSWindowDelegate>
    // id<MTLDevice> device;
    // CAMetalLayer *metalLayer;
@end
@implementation WindowDelegate

    - (BOOL) windowShouldClose:(NSWindow *)sender { return YES; }

    - (void) windowDidResize:(NSNotification *)notification
    {
        NSWindow* w = notification.object;
        NSSize newSize = w.contentView.frame.size;
        // adjust your view or content here…

        // _MetalLayer.drawableSize = CGSizeMake(690, 690);
        // _MetalLayer.contentsScale = win.backingScaleFactor;
    }

    // - (void) windowDidBecomeKey:(NSNotification *)notification
    // {
    //     // Window became the key (focused) window.
    // }

@end

extern "C"
{
    void init_and_open_window_osx ()
    {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        @autoreleasepool
        {
            NSApplication *app = [NSApplication sharedApplication];
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

            [app run]; // runModalForWindow beginModalSessionForWindow

            // render();
        }

        // [pool drain];
    }

    // void focus_window_osx ()
    // {
    //     [NSApp activate];
    // }
}