//
//  GameScene.swift
//  Dumbo
//
//  Created by Febrian Daniel on 14/06/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var karakter: SKSpriteNode!
    var touchLocation = CGPoint()
    
    var cameraNode = SKCameraNode()
    var cameraMovePointPerSecond: CGFloat = 150.0
    
    var lastUpdateTime: TimeInterval = 0.0
    var dt: TimeInterval = 0.0
    
    var playableRect: CGRect {
        let ratio: CGFloat
        
        switch UIScreen.main.nativeBounds.height {
        case 2688, 1792, 2436:
            ratio = 2.16
        default:
            ratio = 16/9
        }
        
        let playableHeight = size.width
        let playableMargin = (size.height - playableHeight) / 2.0
        
        return CGRect(x: 0.0, y: playableMargin, width: size.width, height: playableHeight)
    }
    
    //    var cameraRect: CGRect {
    //        let width = playableRect.width
    //        let height = playableRect.height
    //        let x = cameraNode.position.x - size.width/2.0 + (size.width - width)/2.0
    //        let y = cameraNode.position.y - size.height/2.0 + (size.height - height)/2.0
    //
    //        return CGRect(x: x, y: y, width: width, height: height)
    //    }
    
    let playerCategory: UInt32 = 0x1 << 0
    let obstacleCategory: UInt32 = 0x1 << 1
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        createBG()
        createPlayer()
        setupCamera()
        startObstacleSpawn()
    }
    
    func createBG() {
        for i in 0...2 {
            let bg = SKSpriteNode(imageNamed: "bg")
            bg.name = "BG"
            bg.position = CGPoint(x: CGFloat(i) * bg.frame.width, y: 0)
            bg.zPosition = -1.0
            addChild(bg)
            print(bg.position)
        }
    }
    
    func createPlayer() {
        karakter = SKSpriteNode(imageNamed: "karakter")
        karakter.name = "Player"
        karakter.zPosition = 5.0
        karakter.position = CGPoint(x: -frame.width/3, y: 0)
        addChild(karakter)
        
        // Add physics body to the player for collision detection
        karakter.physicsBody = SKPhysicsBody(rectangleOf: karakter.size)
        //        karakter.physicsBody?.categoryBitMask = playerCategory
        //        karakter.physicsBody?.collisionBitMask = obstacleCategory
        //        karakter.physicsBody?.contactTestBitMask = obstacleCategory
        karakter.physicsBody?.affectedByGravity = false
    }
    
    func setupCamera() {
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    func startObstacleSpawn() {
        let spawnAction = SKAction.run { [weak self] in
            self?.addObstacle()
        }
        
        let waitAction = SKAction.wait(forDuration: 1.0)
        
        let spawnSequence = SKAction.sequence([spawnAction, waitAction])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        
        run(spawnForever, withKey: "spawnObstacles")
    }
    
    func stopObstacleSpawn() {
        removeAction(forKey: "spawnObstacles")
    }
    
    func addObstacle() {
        let obstacle = SKSpriteNode(imageNamed: "obst")
        
        let minY = playableRect.minY + obstacle.size.height/2
        let maxY = playableRect.maxY - obstacle.size.height*2
        let randomY = CGFloat.random(in: minY...maxY)
        
        let cameraOffset = cameraNode.position.x - size.width / 2.0
        let obstacleX = size.width + obstacle.size.width + cameraOffset
        
        obstacle.position = CGPoint(x: obstacleX, y: randomY/* Set the Y position based on your desired layout */)
        
        addChild(obstacle)
        
        // Add physics body to the obstacle for collision detection
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.collisionBitMask = playerCategory
        obstacle.physicsBody?.contactTestBitMask = playerCategory
        obstacle.physicsBody?.affectedByGravity = false
        
        let floatingAction = SKAction.applyForce(CGVector(dx: 0.0, dy: 10.0), duration: 1)
        let reverseFloatingAction = SKAction.applyForce(CGVector(dx: 0.0, dy: -20.0), duration: 1)
        let floatingSequence = SKAction.sequence([floatingAction, reverseFloatingAction])
        let floatingRepeat = SKAction.repeatForever(floatingSequence)
        
        obstacle.run(floatingRepeat)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == playerCategory | obstacleCategory {
            // Collision between player and obstacle detected
            if let obstacle = contact.bodyA.node as? SKSpriteNode {
                obstacle.removeFromParent()
            } else if let obstacle = contact.bodyB.node as? SKSpriteNode {
                obstacle.removeFromParent()
            }
            
            // Handle any other collision-related logic
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchLocation = touch.location(in: self)
            karakter.position.y = touchLocation.y
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchLocation = touch.location(in: self)
            karakter.position.y = touchLocation.y
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        
        lastUpdateTime = currentTime
        moveCamera()
        movePlayer()
        //        moveBackground()
        //        moveObstacles()
    }
    
    func moveCamera() {
        let amountToMove = CGPoint(x: cameraMovePointPerSecond * CGFloat(dt), y: 0.0)
        
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "BG") { (node, _) in
            let node = node as! SKSpriteNode
            
            if node.position.x + node.frame.width < self.cameraNode.frame.origin.x {
                node.position = CGPoint(x: node.position.x + node.frame.width * 2.0, y: node.position.y)
            }
        }
    }
    
    func movePlayer(){
        let amountToMove = cameraMovePointPerSecond * CGFloat(dt)
        karakter.position.x += amountToMove
    }
}

