//
//  GEFont.swift
//  GameEngine
//
//  Created by Anthony Green on 2/15/16.
//  Copyright © 2016 Anthony Green. All rights reserved.
//

//TODO: check if those casts ever get fixed

import CoreText
import Foundation
import GLKit
import Metal
import UIKit

class GETextLabel: GENode, Renderable {
  private typealias GlyphClosure = (glyph: CGGlyph, bounds: CGRect) -> ()

  var text: String
  let fontAtlas: FontAtlas
  let color: UIColor

  let displaySize = 72 //arbitrary right now for testing

  var vertices = Vertices()
  var texture: MTLTexture? = nil
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var sharedUniformBuffer: MTLBuffer!
  var uniformBufferQueue: BufferQueue!

  var rects: Quads!

  init(text: String, font: UIFont, color: UIColor) {
    self.text = text
    self.fontAtlas = Fonts.cache.fontForUIFont(font)!
    self.color = color
  }

  func updateVertices(device: MTLDevice) {
    let vertexData = self.vertices.flatMap { $0.data }
    let vertexDataSize = vertexData.count * sizeofValue(vertexData[0])
    vertexBuffer = device.newBufferWithBytes(vertexData, length: vertexDataSize, options: [])
  }

  //need a size that fits rect sort of thing for the text
  func loadTexture(device: MTLDevice) {
    let rect = CGRect(x: 0.0, y: 0.0, width: 400.0, height: 400.0)

    let attr = [NSFontAttributeName: fontAtlas.font]
    let attrStr = NSAttributedString(string: text, attributes: attr)

    let strRng = CFRangeMake(0, attrStr.length)
    let rectPath = CGPathCreateWithRect(rect, nil)
    let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
    let frame = CTFramesetterCreateFrame(framesetter, strRng, rectPath, nil)

//    let lines = CTFrameGetLines(frame) as [AnyObject] as! [CTLine] //lol
//    let frameGlyphCount = lines.reduce(0) {
//      $0 + CTLineGetGlyphCount($1)
//    }

    //var vertices = Vertices()
    var rects = Quads()
    enumerateGlyphsInFrame(frame) { glyph, glyphBounds in
      //TODO: this probably needs to change to a dictionary because I'm not pulling out all the values
      //let glyphInfo = self.fontAtlas.glyphDescriptors[Int(glyph)]
      let tmpGlyphs = self.fontAtlas.glyphDescriptors.filter {
        return glyph == $0.glyphIndex
      }
      guard let glyphInfo = tmpGlyphs.first else { return }

      let minX = Float(CGRectGetMinX(glyphBounds))
      let maxX = Float(CGRectGetMaxX(glyphBounds))
      let minY = Float(CGRectGetMinY(glyphBounds))
      let maxY = Float(CGRectGetMaxY(glyphBounds))
      let minS = Float(glyphInfo.topLeftTexCoord.x)
      let maxS = Float(glyphInfo.bottomRightTexCoord.x)
      let minT = Float(glyphInfo.topLeftTexCoord.y)
      let maxT = Float(glyphInfo.bottomRightTexCoord.y)

      let ll = SpriteVertex(s: minS, t: maxT, x: minX, y: minY)
      let ul = SpriteVertex(s: minS, t: minT, x: minX, y: maxY)
      let ur = SpriteVertex(s: maxS, t: minT, x: maxX, y: maxY)
      let lr = SpriteVertex(s: maxS, t: maxT, x: maxX, y: minY)
      rects += [Quad(ll: ll, ul: ul, ur: ur, lr: lr)]
    }

    self.rects = rects

    let texDesc = MTLTextureDescriptor()
    let textureSize = fontAtlas.textureSize
    texDesc.pixelFormat = .R8Unorm
    texDesc.width = textureSize
    texDesc.height = textureSize
    texture = device.newTextureWithDescriptor(texDesc)

    let region = MTLRegionMake2D(0, 0, textureSize, textureSize)
    texture!.replaceRegion(region, mipmapLevel: 0, withBytes: fontAtlas.textureData.bytes, bytesPerRow: textureSize)
  }

  private func enumerateGlyphsInFrame(frame: CTFrameRef, closure: GlyphClosure) {
    let entire = CFRangeMake(0, 0)

    let framePath = CTFrameGetPath(frame)
    let frameBoundingRect = CGPathGetPathBoundingBox(framePath)

    let lines = CTFrameGetLines(frame) as [AnyObject] as! [CTLine] //lol
    let originBuffer = UnsafeMutablePointer<CGPoint>.alloc(lines.count)
    defer { originBuffer.destroy(lines.count); originBuffer.dealloc(lines.count) }
    CTFrameGetLineOrigins(frame, entire, originBuffer)

    UIGraphicsBeginImageContext(CGSize(width: 1.0, height: 1.0))
    var context = UIGraphicsGetCurrentContext()
    
    for (i, line) in lines.enumerate() {
      let lineOrigin = originBuffer[i]

      let runs = CTLineGetGlyphRuns(line) as [AnyObject] as! [CTRun] //lol
      runs.forEach { run in
        let glyphCount = CTRunGetGlyphCount(run)

        let glyphBuffer = UnsafeMutablePointer<CGGlyph>.alloc(glyphCount)
        defer { glyphBuffer.destroy(glyphCount); glyphBuffer.dealloc(glyphCount) }
        CTRunGetGlyphs(run, entire, glyphBuffer)

        //TODO: probably don't need this anymore
        let positionBuffer = UnsafeMutablePointer<CGPoint>.alloc(glyphCount)
        defer { positionBuffer.destroy(); positionBuffer.dealloc(glyphCount) }
        CTRunGetPositions(run, entire, positionBuffer)

        (0..<glyphCount).forEach { j in
          let glyph = glyphBuffer[j]
          let glyphRect = CTRunGetImageBounds(run, context, CFRangeMake(j, 1))
          closure(glyph: glyph, bounds: glyphRect)
        }
      }
    }
    UIGraphicsEndImageContext()
  }
}
