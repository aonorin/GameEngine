//
//  Projection.swift
//  GameEngine
//
//  Created by Anthony Green on 5/22/16.
//  Copyright © 2016 Anthony Green. All rights reserved.
//

import simd

struct Projection {
  private(set) var projection: Mat4

  init(size: Size) {
    projection = Mat4.orthographic(right: size.width, top: size.height)
  }

  mutating func update(size: Size) {
    projection = Mat4.orthographic(right: size.width, top: size.height)
  }
}
