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
static const uint32_t asteroidCategory          =  0x1 << 2;

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

@property NSMutableArray* asteroids;
@property SKSpriteNode* player;

@end

#pragma mark -

@implementation BBUMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectInset(self.frame, -100.0, -100.0)];
        self.physicsBody.categoryBitMask = worldCategory;
        self.physicsBody.usesPreciseCollisionDetection = YES;
        
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        self.player.size = CGSizeMake(75.0, 65.0);
        self.player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.player.size];
        self.player.physicsBody.categoryBitMask = playerCategory;
        self.player.physicsBody.contactTestBitMask = worldCategory | asteroidCategory;
        self.player.physicsBody.usesPreciseCollisionDetection = YES;
        self.player.position = CGPointMake((self.size.width - self.player.size.width) / 2,
                                           (self.size.height - self.player.size.height) / 2);
        self.player.zRotation = DegreesToRadians(45.0);
        [self addChild:self.player];
        
        self.asteroids = [@[] mutableCopy];
        for (int i = 0; i < arc4random_uniform(20); i++) {
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, CGRectMake(0.0, 0.0, 50.0, 50.0));
            
            SKShapeNode* asteroid = [SKShapeNode node];
            asteroid.fillColor = [UIColor brownColor];
            asteroid.path = path;
            asteroid.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:25.0];
            asteroid.physicsBody.categoryBitMask = asteroidCategory;
            asteroid.physicsBody.contactTestBitMask = worldCategory;
            asteroid.physicsBody.usesPreciseCollisionDetection = YES;
            asteroid.position = CGPointMake(arc4random_uniform(self.size.width), arc4random_uniform(self.size.height));
            [self addChild:asteroid];
        
            [self addRandomMovementToNode:asteroid];
            [self.asteroids addObject:asteroid];
        }
    }
    return self;
}

-(void)addRandomMovementToNode:(SKNode*)node {
    CGFloat xDirection = arc4random_uniform(5) - 3.0;
    CGFloat yDirection = arc4random_uniform(5) - 3.0;
    SKAction* move = [SKAction moveBy:CGVectorMake(5 * xDirection, 5 * yDirection)
                             duration:0.1];
    [node runAction:[SKAction repeatActionForever:move] withKey:kMovementAction];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

#pragma mark - Collision detection

-(SKNode*)contactedAsteroid:(SKPhysicsContact*)contact {
    for (SKNode* node in self.asteroids) {
        if (contact.bodyA == node.physicsBody || contact.bodyB == node.physicsBody) {
            return node;
        }
    }
    
    return nil;
}

-(BOOL)contactedPlayer:(SKPhysicsContact*)contact {
    return contact.bodyA == self.player.physicsBody || contact.bodyB == self.player.physicsBody;
}

-(BOOL)contactedWorld:(SKPhysicsContact*)contact {
    return contact.bodyA == self.physicsBody || contact.bodyB == self.physicsBody;
}

-(void)handleOutOfWorldContact:(SKPhysicsContact*)contact ofNode:(SKNode*)node {
    CGPoint newPosition = CGPointMake(self.size.width - contact.contactPoint.x, self.size.height - contact.contactPoint.y);
    
    if (contact.contactPoint.x <= 0.0) {
        newPosition.x = self.size.width;
    } else if (contact.contactPoint.x >= self.size.width) {
        newPosition.x = 0.0;
    } else if (contact.contactPoint.y <= 0.0) {
        newPosition.y = self.size.height;
    } else {
        newPosition.y = 0.0;
    }
    
    [node runAction:[SKAction moveTo:newPosition duration:0.0]];
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    //NSLog(@"Collision of %@ and %@ at %@.", contact.bodyA, contact.bodyB, NSStringFromCGPoint(contact.contactPoint));
    
    if ([self contactedPlayer:contact] && [self contactedWorld:contact]) {
        [self handleOutOfWorldContact:contact ofNode:self.player];
    }
    
    SKNode* contactedAsteroid = [self contactedAsteroid:contact];
    
    if ([self contactedWorld:contact] && contactedAsteroid) {
        [self handleOutOfWorldContact:contact ofNode:contactedAsteroid];
    }
    
    if ([self contactedPlayer:contact] && contactedAsteroid) {
        [contactedAsteroid runAction:[SKAction removeFromParent]];
        [self.player runAction:[SKAction removeFromParent]];
        
        NSString* path = [[NSBundle mainBundle] pathForResource:@"Explosion" ofType:@"sks"];
        SKEmitterNode* explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        explosion.position = contact.contactPoint;
        [self addChild:explosion];
        
        [explosion runAction:[SKAction sequence:@[[SKAction waitForDuration:1.0], [SKAction removeFromParent]]]];
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
