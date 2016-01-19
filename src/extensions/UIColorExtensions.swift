//
//  UIColorExtensions.swift
//  MKTest
//
//  Created by Tony Green on 12/30/15.
//  Copyright © 2015 Tony Green. All rights reserved.
//

import UIKit

extension UIColor {
  var rgb: (r: Float, g: Float, b: Float, a: Float) {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      return (Float(red), Float(green), Float(blue), Float(alpha))
    }
    return (0.0, 0.0, 0.0, 1.0) //just return white on error
  }
}