//
//  BBUMyScene.m
//  SpaceDemo
//
//  Created by Boris Bügling on 03.10.13.
//  Copyright (c) 2013 Boris Bügling. All rights reserved.
//

#import "BBUMyScene.h"

static NSString* kMovementAction = @"MovementAction";

static const uint32_t worldCategory             =  0x1 << 0;
static const uint32_t playerCategory            =  0x1 << 1;

CGFloat DegreesToRadians(CGFloat degrees)
{
    return degrees * M_PI / 180;
};

static CGPathRef createPathRotatedAroundBoundingBoxCenter(CGPathRef path, CGFloat radians) {
    CGRect bounds = CGPathGetPathBoundingBox(path);
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, center.x, center.y);
    transform = CGAffineTransformRotate(transform, radians);
    transform = CGAffineTransformTranslate(transform, -center.x, -center.y);
    return CGPathCreateCopyByTransformingPath(path, &transform);
}

#pragma mark -

@interface BBUMyScene () <SKPhysicsContactDelegate>

@property SKSpriteNode* player;

@end

#pragma mark -

@implementation BBUMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(-size.width, -size.height,
                                                                              size.width * 3, size.height * 3)];
        self.physicsBody.categoryBitMask = worldCategory;
        
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        self.player.size = CGSizeMake(75.0, 65.0);
        self.player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.player.physicsBody.categoryBitMask = playerCategory;
        self.player.physicsBody.contactTestBitMask = worldCategory;
        self.player.position = CGPointMake((self.size.width - self.player.size.width) / 2,
                                           (self.size.height - self.player.size.height) / 2);
        self.player.zRotation = DegreesToRadians(45.0);
        [self addChild:self.player];
    }
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

#pragma mark - Collision detection

-(BOOL)contactedPlayer:(SKPhysicsContact*)contact {
    return contact.bodyA == self.player.physicsBody || contact.bodyB == self.player.physicsBody;
}

-(BOOL)contactedWorld:(SKPhysicsContact*)contact {
    return contact.bodyA == self.physicsBody || contact.bodyB == self.physicsBody;
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    //NSLog(@"Collision of %@ and %@ at %@.", contact.bodyA, contact.bodyB, NSStringFromCGPoint(contact.contactPoint));
    
    if ([self contactedPlayer:contact] && [self contactedWorld:contact]) {
        CGPoint newPosition = CGPointMake(self.size.width - contact.contactPoint.x, self.size.height - contact.contactPoint.y);
        
        if (contact.contactPoint.x < 0.0) {
            newPosition.x = self.size.width;
        } else if (contact.contactPoint.x > self.size.width) {
            newPosition.x = 0.0;
        } else if (contact.contactPoint.y < 0.0) {
            newPosition.y = self.size.height;
        } else {
            newPosition.y = 0.0;
        }
        
        [self.player runAction:[SKAction moveTo:newPosition duration:0.0]];
    }
}

#pragma mark - Touch handling

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &CGAffineTransformIdentity,
                      self.player.position.x + (self.player.size.width / 2),
                      self.player.position.y);
    CGPathAddLineToPoint(path, &CGAffineTransformIdentity, self.size.width / 2, 0.0);
    
    SKAction* move = [SKAction followPath:createPathRotatedAroundBoundingBoxCenter(path, self.player.zRotation)
                                 duration:1.0].reversedAction;
    [self.player runAction:[SKAction repeatActionForever:move] withKey:kMovementAction];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.player removeActionForKey:kMovementAction];
}

@end
