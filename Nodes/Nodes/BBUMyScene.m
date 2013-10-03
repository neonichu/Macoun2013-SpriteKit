//
//  BBUMyScene.m
//  Nodes
//
//  Created by Boris Bügling on 29.09.13.
//  Copyright (c) 2013 Boris Bügling. All rights reserved.
//

#import "BBUMyScene.h"

@implementation BBUMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Hello, World!";
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        switch (self.type) {
            case 0:
                [self addSpriteAtLocation:location];
                break;
            case 1:
                [self addEmitterAtLocation:location];
                break;
            case 2:
                [self addVideoAtLocation:location];
                break;
            case 3:
                [self addEffectAtLocation:location];
                break;
            case 4:
                [self addCropAtLocation:location];
                break;
        }
    }
}

-(BOOL)physics {
    return self.physicsBody != nil;
}

-(void)setPhysics:(BOOL)physics {
    if (physics) {
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0.0, 0.0, 1.0, 1.0)];
        
        for (SKNode* node in self.children) {
            node.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:node.calculateAccumulatedFrame.size];
        }
    } else {
        self.physicsBody = nil;
        
        for (SKNode* node in self.children) {
            node.physicsBody = nil;
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

#pragma mark -

-(void)addCropAtLocation:(CGPoint)location {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, CGRectMake(0.0, 0.0, 50.0, 50.0));
    
    SKShapeNode* shape = [SKShapeNode node];
    //shape.fillColor = [UIColor whiteColor];
    shape.path = path;
    
    SKCropNode* crop = [SKCropNode node];
    crop.position = location;
    crop.maskNode = shape;
    
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    [crop addChild:sprite];
    
    [self addChild:crop];
}

-(void)addEffectAtLocation:(CGPoint)location {
    SKEffectNode* effect = [SKEffectNode node];
    //effect.filter = [CIFilter filterWithName:@"CIColorMonochrome"];
    effect.filter = [CIFilter filterWithName:@"CISepiaTone"];
    effect.position = location;
    
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    [effect addChild:sprite];
    
    [self addChild:effect];
}

-(void)addEmitterAtLocation:(CGPoint)location {
    SKEmitterNode* emitter = [SKEmitterNode node];
    emitter.position = location;
    
    emitter.particleBirthRate = 10.0;
    emitter.particleColor = [UIColor redColor];
    emitter.particleLifetime = 100.0;
    emitter.particleSize = CGSizeMake(5.0, 5.0);
    emitter.particleSpeed = 10.0;
    emitter.xAcceleration = 20.0;
    emitter.yAcceleration = 20.0;
    
    [self addChild:emitter];
}

-(void)addSpriteAtLocation:(CGPoint)location {
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    sprite.position = location;
    
    SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
    [sprite runAction:[SKAction repeatActionForever:action]];
    
    [self addChild:sprite];
}

-(void)addVideoAtLocation:(CGPoint)location {
    SKVideoNode* video = [SKVideoNode videoNodeWithVideoFileNamed:@"bipbop.mp4"];
    video.position = location;
    
    [video play];
    
    [self addChild:video];
}

@end
