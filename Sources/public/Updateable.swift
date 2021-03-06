//
//  Updateable.swift
//  GameEngine
//
//  Created by Anthony Green on 2/27/16.
//  Copyright © 2016 Anthony Green. All rights reserved.
//

import Foundation

/**
 Any type that needs to be updated during the main game loop should implement the `Updateable` protocol.
 */
public protocol Updateable: class, Tree {
  var action: Action? { get }
  var hasAction: Bool { get }

  func update(_ delta: CFTimeInterval)
  func runAction(_ action: Action)
  func stopAction()
}
