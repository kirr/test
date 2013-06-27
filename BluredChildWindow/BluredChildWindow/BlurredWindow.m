//
//  BlurredWindow.m
//  BluredChildWindow
//
//  Created by Kirill Kosarev on 6/27/13.
//  Copyright (c) 2013 Kirill Kosarev. All rights reserved.
//

#import "BlurredWindow.h"
#import <objc/runtime.h>

typedef int CGSConnection;
typedef void* CGSWindowFilterRef;
extern OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);
extern CGError CGSNewCIFilterByName(CGSConnection cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
extern CGError CGSAddWindowFilter(CGSConnection cid, int wid, CGSWindowFilterRef filter, int flags);
extern CGError CGSRemoveWindowFilter(CGSConnection cid, int wid, CGSWindowFilterRef filter);
extern CGError CGSReleaseCIFilter(CGSConnection cid, CGSWindowFilterRef filter);
extern CGError CGSSetCIFilterValuesFromDictionary(CGSConnection cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);

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

