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
static const uint32_t laserCategory             =  0x1 << 3;

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
@property NSUInteger lives;
@property SKSpriteNode* player;
@property NSUInteger points;
@property SKLabelNode* scoreBoard;

@end

#pragma mark -

@implementation BBUMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.lives = 5;
        self.points = 0;
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectInset(self.frame, -100.0, -100.0)];
        self.physicsBody.categoryBitMask = worldCategory;
        self.physicsBody.usesPreciseCollisionDetection = YES;
        
        self.scoreBoard = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        self.scoreBoard.fontSize = 20.0;
        self.scoreBoard.position = CGPointMake(120.0, 440.0);
        [self updateScoreBoard];
        [self addChild:self.scoreBoard];
        
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
            SKNode* asteroid = [self createAsteroid];
            [self addChild:asteroid];
        
            [self addRandomMovementToNode:asteroid];
            [self.asteroids addObject:asteroid];
        }
        
        for (int i = 0; i < arc4random_uniform(100); i++) {
            NSString* path = [[NSBundle mainBundle] pathForResource:@"Star" ofType:@"sks"];
            SKEmitterNode* star = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            star.position = CGPointMake(arc4random_uniform(self.size.width), arc4random_uniform(self.size.height));
            star.zPosition = -1;
            [self addChild:star];
        }
    }
    return self;
}

-(SKNode*)createAsteroid {
    SKSpriteNode* asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid"];
    asteroid.size = CGSizeMake(50.0, 42.0);
    asteroid.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:25.0];
    asteroid.physicsBody.categoryBitMask = asteroidCategory;
    asteroid.physicsBody.contactTestBitMask = laserCategory | worldCategory;
    asteroid.physicsBody.usesPreciseCollisionDetection = YES;
    asteroid.position = CGPointMake(arc4random_uniform(self.size.width), arc4random_uniform(self.size.height));
    return asteroid;
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

-(void)updateScoreBoard {
    self.scoreBoard.text = [NSString stringWithFormat:@"Score: %d - Lives: %d", self.points, self.lives];
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

-(BOOL)contactedLaser:(SKPhysicsContact*)contact {
    if (self.player.children.count == 0) {
        return NO;
    }
    
    SKPhysicsBody* laserBody = [self.player.children[0] physicsBody];
    return contact.bodyA == laserBody || contact.bodyB == laserBody;
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
    if ([self contactedPlayer:contact] && [self contactedWorld:contact]) {
        [self handleOutOfWorldContact:contact ofNode:self.player];
    }
    
    SKNode* contactedAsteroid = [self contactedAsteroid:contact];
    
    if ([self contactedWorld:contact] && contactedAsteroid) {
        [self handleOutOfWorldContact:contact ofNode:contactedAsteroid];
    }
    
    if ([self contactedPlayer:contact] && contactedAsteroid) {
        [contactedAsteroid runAction:[SKAction removeFromParent]];
        [self.asteroids removeObject:contactedAsteroid];
        [self.player runAction:[SKAction removeFromParent]];
        
        NSString* path = [[NSBundle mainBundle] pathForResource:@"Explosion" ofType:@"sks"];
        SKEmitterNode* explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        explosion.position = contact.contactPoint;
        [self addChild:explosion];
        
        [explosion runAction:[SKAction sequence:@[[SKAction playSoundFileNamed:@"102734__sarge4267__explosion4.wav"
                                                             waitForCompletion:YES],
                                                  [SKAction runBlock:^{
            self.lives--;
            
            if (self.lives == 0) {
                for (SKNode* node in self.children) {
                    [node runAction:[SKAction removeFromParent]];
                }
                
                SKLabelNode* gameOver = [SKLabelNode node];
                
                gameOver.text = @"Game Over";
                gameOver.fontSize = 30;
                gameOver.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
                
                [self addChild:gameOver];
                return;
            } else {
                [self addChild:self.player];
            }
            
            [self updateScoreBoard];
        }],
                                                  [SKAction removeFromParent],
                                                  ]]];
    }
    
    if (contactedAsteroid && [self contactedLaser:contact] && self.children.count < 100) {
        self.points += 500;
        [self updateScoreBoard];
        
        [contactedAsteroid removeAllActions];
        [contactedAsteroid runAction:[SKAction removeFromParent]];
        [self.asteroids removeObject:contactedAsteroid];
        
        CGRect boundingRect = contactedAsteroid.calculateAccumulatedFrame;
        boundingRect.origin = CGPointZero;
        
        CGRect firstHalf = CGRectMake(0.0, 0.0, CGRectGetMidX(boundingRect), boundingRect.size.height);
        CGRect secondHalf = CGRectMake(firstHalf.size.width, 0.0, boundingRect.size.width, boundingRect.size.height);
        
        SKAction* wait = [SKAction waitForDuration:0.2];
        SKAction* addAsteroidPieces = [SKAction runBlock:^{
            [self addCroppedAsteroidForRect:firstHalf withOriginalNode:contactedAsteroid];
            [self addCroppedAsteroidForRect:secondHalf withOriginalNode:contactedAsteroid];
        }];
        
        [self runAction:[SKAction sequence:@[ wait, addAsteroidPieces ]]];
    }
}

-(void)addCroppedAsteroidForRect:(CGRect)rect withOriginalNode:(SKNode*)originalNode {
    SKNode* asteroid = [self createAsteroid];
    asteroid.position = CGPointZero;
    
    SKCropNode* crop = [self makeCropNodeForRect:rect];
    crop.position = originalNode.position;
    
    crop.physicsBody = asteroid.physicsBody;
    crop.physicsBody.categoryBitMask = 0;
    asteroid.physicsBody = nil;
    
    [crop addChild:asteroid];
    [self addChild:crop];
    
    [crop runAction:[SKAction waitForDuration:0.2] completion:^{
        [self addRandomMovementToNode:crop];
    }];
    
    [self.asteroids addObject:crop];
}

-(SKCropNode*)makeCropNodeForRect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, &CGAffineTransformIdentity, rect);
    
    SKShapeNode* half = [SKShapeNode node];
    half.fillColor = [UIColor whiteColor];
    half.path = path;
    
    SKCropNode* maskHalf = [SKCropNode node];
    maskHalf.maskNode = half;
    
    return maskHalf;
}

#pragma mark - Touch handling

-(void)rotatePlayerWithEndPoint:(CGPoint)endPoint {
    CGFloat deltaX = endPoint.x - self.player.position.x;
    CGFloat deltaY = endPoint.y - self.player.position.y;
    
    CGFloat angleInDegrees = -atan2f(deltaY, deltaX) * 180.0 / M_PI;
    
    self.player.zRotation = DegreesToRadians(angleInDegrees);
}

-(void)rotatePlayerAndMoveForwardWithTouchPoint:(CGPoint)point {
    [self.player removeActionForKey:kMovementAction];
    
    [self rotatePlayerWithEndPoint:point];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &CGAffineTransformIdentity,
                      self.player.position.x + (self.player.size.width / 2),
                      self.player.position.y);
    CGPathAddLineToPoint(path, &CGAffineTransformIdentity, self.size.width / 2, 0.0);
    
    SKAction* move = [SKAction followPath:createPathRotatedAroundBoundingBoxCenter(path, self.player.zRotation)
                                 duration:5.0].reversedAction;
    [self.player runAction:[SKAction repeatActionForever:move] withKey:kMovementAction];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self rotatePlayerAndMoveForwardWithTouchPoint:[[touches anyObject] locationInView:self.view]];
    
    SKEmitterNode* laser = [SKEmitterNode node];
    laser.particleBirthRate = 3.0;
    laser.particleColor = [UIColor greenColor];
    laser.particleLifetime = 100.0;
    laser.particleRotation = DegreesToRadians(90.0);
    laser.particleSize = CGSizeMake(10.0, 1.0);
    laser.particleSpeed = 10.0;
    laser.position = CGPointMake(0.0, 35.0);
    laser.yAcceleration = 50.0;
    laser.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:laser.position
                                                     toPoint:CGPointMake(laser.position.x,
                                                                         laser.position.y + laser.particleSize.width)];
    laser.physicsBody.categoryBitMask = laserCategory;
    [self.player addChild:laser];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.player removeActionForKey:kMovementAction];
    [self.player removeAllChildren];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self rotatePlayerAndMoveForwardWithTouchPoint:[[touches anyObject] locationInView:self.view]];
}

@end
