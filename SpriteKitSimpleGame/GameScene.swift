//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by John Seabolt on 11/22/17.
//  Copyright © 2017 John Seabolt. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    let label = SKLabelNode(fontNamed: "Chalkduster")
    var monstersDestroyed = 0
    var monstersCreated = 0
    let lastGhost = 50
    
    override func didMove(to view: SKView) {
        label.text = "\(String(monstersDestroyed))/\(lastGhost)"
        label.fontSize = 20
        label.fontColor = SKColor.white
        label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.9 )
        addChild(label)
        
        let background = SKSpriteNode(imageNamed: "main_background")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        backgroundColor = SKColor.black
        player.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        addChild(player)
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run(addMonster)
            ])
        ))
        let backgroundMusic = SKAudioNode(fileNamed: "Sounds/song.m4a")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        // Create sprite
        monstersCreated += 1
        var monster: SKSpriteNode?
        if(monstersCreated < lastGhost) {
            monster = SKSpriteNode(imageNamed: "monster")
        } else if monstersCreated == lastGhost {
            monster = SKSpriteNode(imageNamed: "ghost")
        }
        
        if let monster = monster {
            // Determine where to spawn the monster along the Y axis
            let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
            
            // Position the monster slightly off-screen along the right edge,
            // and along a random position along the Y axis as calculated above
            monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
            
            // Add the monster to the scene
            addChild(monster)
            
            monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
            monster.physicsBody?.isDynamic = true
            monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
            monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
            monster.physicsBody?.collisionBitMask = PhysicsCategory.None
            
            // Determine speed of the monster
            let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
            
            // Create the actions
            let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
            let actionMoveDone = SKAction.removeFromParent()
            let loseAction = SKAction.run() {
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameOverScene = GameOverScene(size: self.size, won: false)
                self.view?.presentScene(gameOverScene, transition: reveal)
            }
            monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        run(SKAction.playSoundFileNamed("Sounds/pew-pew-lei.caf", waitForCompletion: false))
        
        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        projectile.removeFromParent()
        monster.removeFromParent()
        monstersDestroyed += 1
        
        
        label.text = "\(String(monstersDestroyed))/\(lastGhost)"
        
        print(monstersDestroyed)
        if (monstersDestroyed >= lastGhost) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let
                projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
    }
}
