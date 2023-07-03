import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hasShownContinueButton: Bool = false
    var gameViewController: GameViewController?
    var isGameActive = false
    var continueGameLabel: SKLabelNode?
    var fireParticles: SKEmitterNode?
    private var isGameStarted = false
    private var startGameLabel: SKLabelNode?
    private var ball = SKShapeNode()
    private var scoreLabel: SKLabelNode?
    private var gameOverLabel: SKLabelNode?
    private var score: Int = 0 {
        didSet {
            self.scoreLabel?.text = "\(score)"
            let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            self.scoreLabel?.run(SKAction.sequence([scaleUp, scaleDown]))
            scoreLabel?.zPosition = 100  // Set a high zPosition
        }
    }
    
    var gameSpeed: TimeInterval = 1.0 // Vitesse initiale du jeu
    var gapHeight: CGFloat = 300.0 // Hauteur initiale des trous dans les murs
    var wallMovementSpeed: CGFloat = 1.0 // Vitesse à laquelle les murs bougent de gauche à droite
    struct PhysicsCategories {
        static let none: UInt32 = 0
        static let ball: UInt32 = 0x1 << 0
        static let wall: UInt32 = 0x1 << 1
        static let score: UInt32 = 0x1 << 2
    }
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0)
        self.backgroundColor = UIColor.white

        let lightBlue = UIColor(red: 173/255, green: 216/255, blue: 230/255, alpha: 1)
        let lightGreen = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)
        let lightYellow = UIColor(red: 255/255, green: 255/255, blue: 224/255, alpha: 1)
        let lightRed = UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 1)
        let lightGray = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1)

        let colorChange = SKAction.sequence([
            SKAction.colorize(with: lightYellow, colorBlendFactor: 1.0, duration: 10.7),
            SKAction.colorize(with: lightGreen, colorBlendFactor: 3.0, duration: 14.6),
            SKAction.colorize(with: lightRed, colorBlendFactor: 1.0, duration: 20),
            SKAction.colorize(with: lightGray, colorBlendFactor: 1.0, duration: 12.5),
            SKAction.colorize(with: lightBlue, colorBlendFactor: 1.0, duration: 14),

        ])
        let colorChangeLoop = SKAction.repeatForever(colorChange)
        self.run(colorChangeLoop)

        self.ball = SKShapeNode(circleOfRadius: 50)
        self.ball.position = CGPoint(x: frame.midX, y: frame.minY + 150)
        self.ball.fillColor = UIColor.red
        self.ball.strokeColor = UIColor.black
        self.ball.glowWidth = 1.0  // Effet de lueur ajouté
        self.ball.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        self.ball.physicsBody?.isDynamic = true
        self.ball.physicsBody?.categoryBitMask = PhysicsCategories.ball
        self.ball.physicsBody?.collisionBitMask = PhysicsCategories.wall
        self.ball.physicsBody?.contactTestBitMask = PhysicsCategories.wall | PhysicsCategories.score

        if let fireParticles = SKEmitterNode(fileNamed: "Fire.sks") {
            fireParticles.position = CGPoint(x: 0, y: 0)
            fireParticles.zPosition = -1 // make sure fire is under the ball
            fireParticles.emissionAngle = CGFloat.pi / 2  // emits particles sideways
            fireParticles.emissionAngleRange = CGFloat.pi * 2  // emits particles in all directions
            fireParticles.particleBirthRate = 0  // start with no fire
            self.fireParticles = fireParticles
            self.ball.addChild(fireParticles)
        }



        self.addChild(ball)

        self.scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        self.scoreLabel?.text = "Score"
        self.scoreLabel?.fontSize = 40 // Increase font size
        self.scoreLabel?.fontColor = UIColor.black // Set font color to black
        self.scoreLabel?.position = CGPoint(x: frame.minX + 170, y: frame.maxY - 50)

        self.addChild(self.scoreLabel!)

        self.physicsWorld.contactDelegate = self

        self.startGameLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        self.startGameLabel?.text = "Touch to Start"
        self.startGameLabel?.fontSize = 60 // Increase font size
        self.startGameLabel?.fontColor = UIColor.black // Set font color to black
        self.startGameLabel?.position = CGPoint(x: frame.midX, y: frame.midY)

        self.addChild(self.startGameLabel!)
    }


    func addWall() {
        let wallThickness: CGFloat = 100.0

        let minimumGapCenter = frame.minX + wallThickness + gapHeight / 2
        let maximumGapCenter = frame.maxX - wallThickness - gapHeight / 2

        let gapCenter = CGFloat.random(in: minimumGapCenter...maximumGapCenter)

        let leftWallRightEdge = gapCenter - gapHeight / 2
        let rightWallLeftEdge = gapCenter + gapHeight / 2

        let leftWallSize = CGSize(width: leftWallRightEdge - frame.minX, height: wallThickness)
        let rightWallSize = CGSize(width: frame.maxX - rightWallLeftEdge, height: wallThickness)

        let leftWall = createWall(size: leftWallSize, position: CGPoint(x: frame.minX + leftWallSize.width / 2, y: frame.maxY + wallThickness / 2))
        let rightWall = createWall(size: rightWallSize, position: CGPoint(x: rightWallLeftEdge + rightWallSize.width / 2, y: frame.maxY + wallThickness / 2))

        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: frame.midX, y: frame.maxY + wallThickness)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: wallThickness))
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategories.score
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategories.ball
        scoreNode.physicsBody?.collisionBitMask = PhysicsCategories.none

        self.addChild(scoreNode)
        self.addChild(leftWall)
        self.addChild(rightWall)

        let netSize = CGSize(width: rightWallLeftEdge - leftWallRightEdge, height: wallThickness)
        let net = SKSpriteNode(imageNamed: "netImage")
        net.size = netSize
        net.position = CGPoint(x: frame.midX, y: frame.maxY + wallThickness / 2)
        self.addChild(net)
        
        
        var moveDuration = gameSpeed * 2

        // Adjust game parameters based on score
        if score >= 0 {
                   moveDuration = gameSpeed * 1
                   wallAddInterval = 1
                   gapHeight = 250
                   wallMovementSpeed = 1.7
               }
               if score >= 10 {
                   moveDuration = gameSpeed * 1
                   wallAddInterval = 0.7
                   gapHeight = 250
                   wallMovementSpeed = 1.8
               }
               if score >= 25 {
                   moveDuration = gameSpeed * 1
                   wallAddInterval = 0.7
                   gapHeight = 220
                   wallMovementSpeed = 2
               }
               
               if score >= 50 {
                   moveDuration = gameSpeed * 1
                   wallAddInterval = 0.6
                   gapHeight = 180
                   wallMovementSpeed = 2
               }
               
               if score >= 70 {
                   moveDuration = gameSpeed * 0.8
                   wallAddInterval = 0.5
                   gapHeight = 180
                   wallMovementSpeed = 2.2
               }
               
               if score >= 100 {
                   moveDuration = gameSpeed * 0.7
                   wallAddInterval = 0.5
                   gapHeight = 180
                   wallMovementSpeed = 2.3
               }

               // Ensure gap height doesn't get too small
               if gapHeight < 100 {
                   gapHeight = 100
               }

        let moveDown = SKAction.moveTo(y: frame.minY - wallThickness, duration: TimeInterval(moveDuration))
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveDown, remove])

        leftWall.run(sequence)
        rightWall.run(sequence)
        scoreNode.run(sequence)

        if Bool.random() {
            let moveSide = SKAction.sequence([
                SKAction.moveBy(x: -50 * wallMovementSpeed, y: 0, duration: 1),
                SKAction.moveBy(x: 100 * wallMovementSpeed, y: 0, duration: 2),
                SKAction.moveBy(x: -50 * wallMovementSpeed, y: 0, duration: 1)
            ])
            let moveSideForever = SKAction.repeatForever(moveSide)
            leftWall.run(moveSideForever)
            rightWall.run(moveSideForever)
        }

    }

    func createWall(size: CGSize, position: CGPoint) -> SKSpriteNode {
        let wall = SKSpriteNode(imageNamed: "wallImage")
        wall.size = size
        wall.position = position
        wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.categoryBitMask = PhysicsCategories.wall
        wall.physicsBody?.collisionBitMask = PhysicsCategories.ball
        wall.physicsBody?.contactTestBitMask = PhysicsCategories.ball
        return wall
    }
    
    private var lastWallAddedTime: TimeInterval = 0.5
    private var wallAddInterval: TimeInterval = 1

    override func update(_ currentTime: TimeInterval) {
        if isGameStarted {
        if currentTime - lastWallAddedTime > wallAddInterval {
            addWall()
            lastWallAddedTime = currentTime
        }
    }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategories.wall || contact.bodyB.categoryBitMask == PhysicsCategories.wall {
            gameOver()
        } else if contact.bodyA.categoryBitMask == PhysicsCategories.score || contact.bodyB.categoryBitMask == PhysicsCategories.score {
            // Seulement augmenter le score quand la balle entre en contact avec le nœud de score
            if contact.bodyA.categoryBitMask == PhysicsCategories.ball || contact.bodyB.categoryBitMask == PhysicsCategories.ball {
                // Pour éviter de marquer plusieurs fois pour un seul passage,
                // vous pouvez retirer le nœud de score après que le score a été augmenté.
                if contact.bodyA.categoryBitMask == PhysicsCategories.score {
                    contact.bodyA.node?.removeFromParent()
                } else if contact.bodyB.categoryBitMask == PhysicsCategories.score {
                    contact.bodyB.node?.removeFromParent()
                }

                score += 1

                // Ajuste l'intensité du feu en fonction du score.
                if score == 10 {
                    fireParticles?.particleBirthRate = 500  // Commence le feu
                } else if score == 25 {
                    fireParticles?.particleBirthRate = 1500  // Rend le feu plus fort
                } else if score == 50 {
                    fireParticles?.particleBirthRate = 3000  // Rend le feu encore plus fort
                }else if score == 70 {
                    fireParticles?.particleBirthRate = 6000  // Rend le feu encore plus fort
                }else if score == 100 {
                    fireParticles?.particleBirthRate = 7000  // Rend le feu encore plus fort
                }

                // Ajoute des messages pour chaque niveau atteint
                switch score {
                case 10:
                    showLevelUpMessage(text: "Chill Level!")
                case 25:
                    showLevelUpMessage(text: "Boss Level!")
                case 50:
                    showLevelUpMessage(text: "Expert Level!")
                case 70:
                    showLevelUpMessage(text: "Master Level!")
                case 100:
                    showLevelUpMessage(text: "Genius Level!")
                default:
                    break
                }
            }
        }
    }

    
    func continueGame() {
        gameViewController?.userDidEarnReward = false
        ball.physicsBody?.isDynamic = false

        // Place the ball back in the center of the screen
        ball.position = CGPoint(x: frame.midX, y: frame.minY + 150)

        // Remove game over popup and labels
        for child in children {
            if child.name == "tryAgain" || child.name == "continueGame" || child.name == "gameOverPopup" || child.name == "gameOverLabel" || child.name == "scoreFinalLabel" {
                child.removeFromParent()
            }
        }

        // Resume the game
        self.ball.physicsBody?.isDynamic = true
    }
    
    
    func startCountdownAndContinueGame() {
        self.isPaused = false // Reprendre la scène
        // Remove game over popup and labels
        for child in children {
            if child.name == "tryAgain" || child.name == "continueGame" || child.name == "gameOverPopup" || child.name == "gameOverLabel" || child.name == "scoreFinalLabel" {
                child.removeFromParent()
            }
        }

        // Place the ball back in the center of the screen
        ball.position = CGPoint(x: frame.midX, y: frame.minY + 150)

        // Create a semi-transparent black background
        let blackout = SKSpriteNode(color: .black, size: self.size)
        blackout.alpha = 0.5
        blackout.zPosition = 100
        blackout.position = CGPoint(x: frame.midX, y: frame.midY)
        self.addChild(blackout)

        // Create countdown label
        let countdownLabel = SKLabelNode(text: "5")
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        countdownLabel.fontColor = UIColor.white
        countdownLabel.fontSize = 300
        countdownLabel.zPosition = 101
        self.addChild(countdownLabel)

        // Start countdown on another thread
        DispatchQueue.global().async {
            for i in (1...5).reversed() {
                DispatchQueue.main.async {
                    countdownLabel.text = "\(i)"
                }
                sleep(1)
            }
            DispatchQueue.main.async {
                countdownLabel.text = "GO"
            }
            sleep(1)
            DispatchQueue.main.async {
                countdownLabel.removeFromParent()
                blackout.removeFromParent() // Remove the semi-transparent black background
                // Continue the game
                self.continueGame()
            }
        }
    }



    func gameOver() {
        self.isPaused = true
        ball.physicsBody?.isDynamic = false
        
        let gameOverPopup = SKShapeNode(rect: self.frame.insetBy(dx: 50, dy: 50), cornerRadius: 30)
        gameOverPopup.name = "gameOverPopup"
        gameOverPopup.fillColor = UIColor.black.withAlphaComponent(0.8)
        gameOverPopup.strokeColor = UIColor.white
        gameOverPopup.lineWidth = 10
        gameOverPopup.zPosition = 100
        self.addChild(gameOverPopup)
        
        self.gameOverLabel = SKLabelNode(text: "GAME OVER")
        self.gameOverLabel?.name = "gameOverLabel"
        self.gameOverLabel?.fontName = "HelveticaNeue-Bold"
        self.gameOverLabel?.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        self.gameOverLabel?.fontColor = UIColor.white
        self.gameOverLabel?.fontSize = 70
        self.gameOverLabel?.zPosition = 101
        self.addChild(self.gameOverLabel!)
        
        let scoreFinalLabel = SKLabelNode(text: "Final Score: \(score)")
        scoreFinalLabel.name = "scoreFinalLabel"
        scoreFinalLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        scoreFinalLabel.fontColor = UIColor.white
        scoreFinalLabel.fontName = "HelveticaNeue"
        scoreFinalLabel.fontSize = 50
        scoreFinalLabel.zPosition = 101
        self.addChild(scoreFinalLabel)
        
        let tryAgainLabel = SKLabelNode(text: "Tap to Try Again")
        tryAgainLabel.name = "tryAgain"
        tryAgainLabel.fontName = "HelveticaNeue"
        tryAgainLabel.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        tryAgainLabel.fontColor = UIColor.white
        tryAgainLabel.fontSize = 50
        tryAgainLabel.zPosition = 101
        self.addChild(tryAgainLabel)
        
        let pulse = SKAction.sequence([SKAction.fadeOut(withDuration: 1.0), SKAction.fadeIn(withDuration: 1.0)])
        let pulseForever = SKAction.repeatForever(pulse)
        gameOverPopup.run(pulseForever)
        
        if !hasShownContinueButton {
            continueGameLabel = SKLabelNode(text: "Continue")
            continueGameLabel?.name = "continueGame"
            continueGameLabel?.fontName = "HelveticaNeue"
            continueGameLabel?.position = CGPoint(x: frame.midX, y: frame.midY - 200)
            continueGameLabel?.fontColor = UIColor.white
            continueGameLabel?.fontSize = 50
            continueGameLabel?.zPosition = 101
            self.addChild(continueGameLabel!)
            
            hasShownContinueButton = true
        }
    }


    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            ball.position = CGPoint(x: location.x, y: ball.position.y) // Keep the ball moving with the finger
        }
        if !isGameActive {
              return
          }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            isGameStarted = true
            startGameLabel?.run(SKAction.fadeOut(withDuration: 0.5))
        } else {
            let location = touches.first?.location(in: self)
            let nodesAtPoint = nodes(at: location!)

            if nodesAtPoint.contains(where: { $0.name == "tryAgain" }) {
                restartGame()
            }    else if nodesAtPoint.contains(where: { $0.name == "continueGame" }) {
                if gameViewController?.userDidEarnReward == true {
                    startCountdownAndContinueGame()
                } else {
                    if let rewardedAd = gameViewController?.rewardedAd {
                        rewardedAd.present(fromRootViewController: gameViewController!, userDidEarnRewardHandler: {
                            self.gameViewController?.userDidEarnReward = true
                            // Move the call to startCountdownAndContinueGame() here
                            self.startCountdownAndContinueGame()
                        })
                    } else {
                        print("Ad wasn't ready")
                    }
                }
            } else {
                ball.position = CGPoint(x: location!.x, y: ball.position.y)
            }

        }
    }

    
    func showLevelUpMessage(text: String) {
           let levelUpLabel = SKLabelNode(text: text)
           levelUpLabel.position = CGPoint(x: frame.midX, y: frame.midY)
           levelUpLabel.fontColor = UIColor.black // Set font color to black
           levelUpLabel.fontSize = 50 // Increase font size
           levelUpLabel.alpha = 0.0
           self.addChild(levelUpLabel)

         let fadeIn = SKAction.fadeIn(withDuration: 0.5)
         let delay = SKAction.wait(forDuration: 2.0)
         let fadeOut = SKAction.fadeOut(withDuration: 0.5)
         let remove = SKAction.removeFromParent()
         let sequence = SKAction.sequence([fadeIn, delay, fadeOut, remove])
         levelUpLabel.run(sequence)
     }
 


    func restartGame() {
        self.physicsWorld.speed = 1 // Reactivate the physics world
        self.physicsWorld.contactDelegate = self // Reassign the contact delegate
        self.removeAllChildren()
        self.backgroundColor = UIColor.white

        score = 0

        ball = SKShapeNode(circleOfRadius: 50)
        ball.position = CGPoint(x: frame.midX, y: frame.minY + 150)
        ball.fillColor = UIColor.red
        ball.strokeColor = UIColor.black
        ball.glowWidth = 1.0  // Reset the glow effect
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.categoryBitMask = PhysicsCategories.ball
        ball.physicsBody?.collisionBitMask = PhysicsCategories.wall
        ball.physicsBody?.contactTestBitMask = PhysicsCategories.score | PhysicsCategories.wall
        
        // Create new fire particles and add them to the ball.
        if let fireParticles = SKEmitterNode(fileNamed: "Fire.sks") {
            fireParticles.position = CGPoint(x: 0, y: 0)
            fireParticles.zPosition = -1 // make sure fire is under the ball
            fireParticles.emissionAngle = CGFloat.pi / 2  // emits particles sideways
            fireParticles.emissionAngleRange = CGFloat.pi * 2  // emits particles in all directions
            fireParticles.particleBirthRate = 0  // start with no fire
            self.fireParticles = fireParticles
            self.ball.addChild(fireParticles)
        }

        self.addChild(ball)

        self.gameOverLabel?.fontName = "Arial-BoldMT"
        self.scoreLabel?.text = "Score"
        self.scoreLabel?.fontSize = 35 // Increase font size
        self.scoreLabel?.fontColor = UIColor.black // Set font color to black
        self.scoreLabel?.position = CGPoint(x: frame.minX + 170, y: frame.maxY - 50)
        self.addChild(scoreLabel!)

        gameSpeed = 1.0
        gapHeight = 300.0
        wallMovementSpeed = 1.0
        lastWallAddedTime = 0.0
        wallAddInterval = 1

        let lightBlue = UIColor(red: 173/255, green: 216/255, blue: 230/255, alpha: 1)
        let lightGreen = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)
        let lightYellow = UIColor(red: 255/255, green: 255/255, blue: 224/255, alpha: 1)
        let lightRed = UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 1)
        let lightGray = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1)

        let colorChange = SKAction.sequence([
            SKAction.colorize(with: lightYellow, colorBlendFactor: 1.0, duration: 10.7),
            SKAction.colorize(with: lightGreen, colorBlendFactor: 3.0, duration: 14.6),
            SKAction.colorize(with: lightRed, colorBlendFactor: 1.0, duration: 20),
            SKAction.colorize(with: lightGray, colorBlendFactor: 1.0, duration: 12.5),
            SKAction.colorize(with: lightBlue, colorBlendFactor: 1.0, duration: 14),
        ])
        let colorChangeLoop = SKAction.repeatForever(colorChange)
        self.run(colorChangeLoop)

        self.isPaused = false
        hasShownContinueButton = false
        gameViewController?.userDidEarnReward = false
    }


}
    
