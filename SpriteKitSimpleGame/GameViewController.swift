//
//  GameViewController.swift
//  SpriteKitSimpleGame
//
//  Created by John Seabolt on 11/22/17.
//  Copyright © 2017 John Seabolt. All rights reserved.
//

import UIKit
import SpriteKit




class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = GameScene(size: view.bounds.size)
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
//        scene.scaleMode = .aspectFill
         scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
