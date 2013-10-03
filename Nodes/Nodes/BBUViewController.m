//
//  BBUViewController.m
//  Nodes
//
//  Created by Boris Bügling on 29.09.13.
//  Copyright (c) 2013 Boris Bügling. All rights reserved.
//

#import "BBUViewController.h"
#import "BBUMyScene.h"

@interface BBUViewController () <UIActionSheetDelegate>

@property UIButton* button;
@property NSArray* buttonTitles;
@property BBUMyScene* scene;

@end

#pragma mark -

@implementation BBUViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.buttonTitles = @[ @"SKSpriteNode", @"SKEmitterNode", @"SKVideoNode", @"SKEffectNode", @"SKCropNode" ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    self.scene = [BBUMyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:self.scene];
    
    self.button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.button.frame = CGRectMake(0.0, 50.0, 150.0, 20.0);
    [self.button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.button setTitle:self.buttonTitles[0] forState:UIControlStateNormal];
    [self.view addSubview:self.button];
}

-(void)tapped:(UIButton*)button {
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:self.buttonTitles[0], self.buttonTitles[1], self.buttonTitles[2], self.buttonTitles[3], self.buttonTitles[4], nil];
    [sheet showFromRect:button.frame inView:self.view animated:YES];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - UIActionSheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex < 0 || buttonIndex > 4) {
        return;
    }
    
    [self.button setTitle:self.buttonTitles[buttonIndex] forState:UIControlStateNormal];
    self.scene.type = buttonIndex;
}

@end
