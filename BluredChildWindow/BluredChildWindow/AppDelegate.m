//
//  AppDelegate.m
//  BluredChildWindow
//
//  Created by Kirill Kosarev on 6/26/13.
//  Copyright (c) 2013 Kirill Kosarev. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/runtime.h>

typedef int CGSConnection;
typedef void* CGSWindowFilterRef;
extern OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);
extern CGError CGSNewCIFilterByName(CGSConnection cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
extern CGError CGSAddWindowFilter(CGSConnection cid, int wid, CGSWindowFilterRef filter, int flags);
extern CGError CGSRemoveWindowFilter(CGSConnection cid, int wid, CGSWindowFilterRef filter);
extern CGError CGSReleaseCIFilter(CGSConnection cid, CGSWindowFilterRef filter);
extern CGError CGSSetCIFilterValuesFromDictionary(CGSConnection cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);

@interface ContentWindow : NSWindow
@end

@implementation ContentWindow
- (BOOL)canBecomeKeyWindow {
    return YES;
}
- (BOOL)_sharesParentKeyState {
   return YES;
}
@end

@interface BlurredWindow : NSWindow
-(void)enableBlur;
@end

@interface BlurredWindow(ShutUpXcode)
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
- (NSWindow*)window;
@end

@implementation BlurredWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    self = [super initWithContentRect:contentRect
                            styleMask:windowStyle
                              backing:bufferingType
                                defer:deferCreation];
    if (!self)
        return nil;
    
    [self setMovableByWindowBackground:YES];
    [self setLevel:NSNormalWindowLevel];
    [self setBackgroundColor: [NSColor colorWithCalibratedHue:0.568 saturation:0.388 brightness:0.941 alpha:0.6]];
//    [self setBackgroundColor:[NSColor clearColor]];
    [self setOpaque:NO];
    [self setHasShadow:NO];
    [self setupCustomFrameDraw];

    return self;
}

- (void)setupCustomFrameDraw {
	// Get window's frame view class
	id class = [[[self contentView] superview] class];
	NSLog(@"class=%@", class);
    
	// Exchange draw rect
	Method m0 = class_getInstanceMethod([self class], @selector(drawRect:));
	class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));
	
	Method m1 = class_getInstanceMethod(class, @selector(drawRect:));
	Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:));
	
	method_exchangeImplementations(m1, m2);
}

-(void)enableBlur {
    CGSConnection thisConnection;
    CGSWindowFilterRef compositingFilter;
    int compositingType = 1 << 0;
    
    // Make a new connection to Core Graphics
    CGSNewConnection(NULL, &thisConnection);
    
    // Create a Core Image filter and set it up
    CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIGaussianBlur", &compositingFilter);
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3] forKey:@"inputRadius"];
    CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);
    
    // Apply the filter to the window
    CGSAddWindowFilter(thisConnection, [self windowNumber], compositingFilter, compositingType);
}

- (void)drawRect:(NSRect)rect
{
    [[NSColor clearColor] set];
    NSRectFill(rect);
    
	// Build clipping path : intersection of frame clip (bezier path with rounded corners) and rect argument
	NSRect windowRect = [[self window] frame];
	windowRect.origin = NSMakePoint(0, 0);
    
	float cornerRadius = [self roundedCornerRadius];
	[[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
	[[NSBezierPath bezierPathWithRect:rect] addClip];
    
	// Draw a background color on top of everything
	CGContextRef context = [[NSGraphicsContext currentContext]graphicsPort];
	CGContextSetBlendMode(context, kCGBlendModeColorDodge);
	[[NSColor colorWithCalibratedRed:0.7 green:0.4 blue:0 alpha:0.4] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
}
@end

@implementation AppDelegate {
    BlurredWindow* blurredWindow_;
}

- (void)dealloc
{
    [blurredWindow_ release];
    [super dealloc];
}

- (void)addImageView {
    NSRect rect = [[[self window] contentView] frame];
    NSImageView* imageView = [[NSImageView alloc] initWithFrame:rect];
    NSImage* img = [[[NSImage alloc] initByReferencingFile:@"/Users/kirr/Desktop/Screen Shot 2013-06-24 at 3.26.50 PM.png"] autorelease];
    [imageView setImage:img];
    [imageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [imageView setAutoresizesSubviews:YES];
    [[[self window] contentView] addSubview:imageView];
    NSRect frame;
    frame.origin = self.window.frame.origin;
    frame.size = img.size;
    [[self window] setFrame:frame display:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self addImageView];

    blurredWindow_ =
        [[BlurredWindow alloc] initWithContentRect:NSMakeRect(100, 100, [[self window] frame].size.width - 20, 100)
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:YES];
    [blurredWindow_ addChildWindow:[self window] ordered: NSWindowBelow];
    [blurredWindow_ orderWindow:NSWindowAbove relativeTo:[[self window] windowNumber]];
    [blurredWindow_ enableBlur];

    [blurredWindow_ setFrameOrigin:NSMakePoint(100, 900)];
    [[self window] setFrameOrigin:NSMakePoint(90, 900 - self.window.frame.size.height + 100 + 30)];

    [blurredWindow_ makeKeyAndOrderFront:nil];
    [[self window] setDelegate:self];
}

- (void)windowDidResize:(NSNotification *)notification {
    NSRect blurredFrame = [blurredWindow_ frame];
    blurredFrame.size.width = self.window.frame.size.width - 20;
    blurredFrame.origin.x = self.window.frame.origin.x + 10;
    blurredFrame.origin.y = self.window.frame.origin.y + self.window.frame.size.height - 30 - 100;
    [blurredWindow_ setFrame:blurredFrame display:YES];
}
@end
