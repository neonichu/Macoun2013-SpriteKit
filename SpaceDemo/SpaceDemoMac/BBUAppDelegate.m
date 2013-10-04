//
//  BBUAppDelegate.m
//  SpaceDemoMac
//
//  Created by Boris Bügling on 04.10.13.
//  Copyright (c) 2013 Boris Bügling. All rights reserved.
//

#import "BBUAppDelegate.h"
#import "BBUMyScene.h"

@implementation BBUAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* Pick a size for the scene */
    SKScene *scene = [BBUMyScene sceneWithSize:CGSizeMake(1024, 768)];

    /* Set the scale mode to scale to fit the window */
    scene.scaleMode = SKSceneScaleModeAspectFit;

    [self.skView presentScene:scene];

    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
