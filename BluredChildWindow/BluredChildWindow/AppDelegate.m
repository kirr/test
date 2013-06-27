//
//  AppDelegate.m
//  BluredChildWindow
//
//  Created by Kirill Kosarev on 6/26/13.
//  Copyright (c) 2013 Kirill Kosarev. All rights reserved.
//

#import "AppDelegate.h"
#import "BlurredWindow.h"

const int kBlurSideOffset = 10;
const int kBlurHeight = 100;
const int kBlurTopOffset = 30;

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
    NSImage* img = [NSImage imageNamed:@"content.png"];
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
        [[BlurredWindow alloc] initWithContentRect:NSMakeRect(100, 100,
                                                              [[self window] frame].size.width - 2*kBlurSideOffset,
                                                              kBlurHeight)
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:YES];
    [blurredWindow_ addChildWindow:[self window] ordered: NSWindowBelow];
    [blurredWindow_ orderWindow:NSWindowAbove relativeTo:[[self window] windowNumber]];
    [blurredWindow_ enableBlur];

    [blurredWindow_ setFrameOrigin:NSMakePoint(100, 900)];
    [[self window] setFrameOrigin:NSMakePoint(100 - kBlurSideOffset,
                                              900 - self.window.frame.size.height + kBlurHeight + kBlurTopOffset)];

    [blurredWindow_ makeKeyAndOrderFront:nil];
    [[self window] setDelegate:self];
}

- (void)windowDidResize:(NSNotification *)notification {
    NSRect blurredFrame = [blurredWindow_ frame];
    blurredFrame.size.width = self.window.frame.size.width - 2*kBlurSideOffset;
    blurredFrame.origin.x = self.window.frame.origin.x + kBlurSideOffset;
    blurredFrame.origin.y = self.window.frame.origin.y + self.window.frame.size.height - kBlurTopOffset - kBlurHeight;
    [blurredWindow_ setFrame:blurredFrame display:YES];
}
@end
