/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import ARKit
import SceneKit

class Pig: SCNNode {
  let occlusionNode: SCNNode

  // Set up brow
  private var neutralBrowY: Float = 0
  private lazy var browNode = childNode(withName: "brow",
                                        recursively: true)!

  // Set up right eye
  private var neutralRightEyeX: Float = 0
  private var neutralRightEyeY: Float = 0
  private lazy var eyeRightNode = childNode(withName: "eyeRight",
                                            recursively: true)!
  private lazy var pupilRightNode = childNode(withName: "pupilRight",
                                              recursively: true)!

  // Set up left eye
  private var neutralLeftEyeX: Float = 0
  private var neutralLeftEyeY: Float = 0
  private lazy var eyeLeftNode = childNode(withName: "eyeLeft",
                                           recursively: true)!
  private lazy var pupilLeftNode = childNode(withName: "pupilLeft",
                                             recursively: true)!

  // Get size of pupils
  private lazy var pupilWidth: Float = {
    let (min, max) = pupilRightNode.boundingBox
    return max.x - min.x
  }()
  private lazy var pupilHeight: Float = {
    let (min, max) = pupilRightNode.boundingBox
    return max.y - min.y
  }()

  // Set up mouth
  private var neutralMouthY: Float = 0
  private lazy var mouthNode = childNode(withName: "mouth",
                                         recursively: true)!

  // Get size of mouth
  private lazy var mouthHeight: Float = {
    let (min, max) = mouthNode.boundingBox
    return max.y - min.y
  }()


  init(geometry: ARSCNFaceGeometry) {
    geometry.firstMaterial!.colorBufferWriteMask = []
    occlusionNode = SCNNode(geometry: geometry)
    occlusionNode.renderingOrder = -1

    super.init()
    self.geometry = geometry

    // 1
    guard let url = Bundle.main.url(forResource: "pig",
                                    withExtension: "scn",
                                    subdirectory: "Models.scnassets")
      else {
        fatalError("Missing resource")
    }

    // 2
    let node = SCNReferenceNode(url: url)!
    node.load()

    // 3
    addChildNode(node)

    // Set Baselines
    neutralBrowY = browNode.position.y
    neutralRightEyeX = pupilRightNode.position.x
    neutralRightEyeY = pupilRightNode.position.y
    neutralLeftEyeX = pupilLeftNode.position.x
    neutralLeftEyeY = pupilLeftNode.position.y
    neutralMouthY = mouthNode.position.y
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  // - Tag: ARFaceAnchor Update
  func update(withFaceAnchor anchor: ARFaceAnchor) {
    blendShapes = anchor.blendShapes
  }

  // - Tag: BlendShapeAnimation
  var blendShapes: [ARFaceAnchor.BlendShapeLocation: Any] = [:] {
    didSet {
      guard

        // 1
        // Brow
        let browInnerUp = blendShapes[.browInnerUp] as? Float,

        // Right eye
        let eyeLookInRight = blendShapes[.eyeLookInRight] as? Float,
        let eyeLookOutRight = blendShapes[.eyeLookOutRight] as? Float,
        let eyeLookUpRight = blendShapes[.eyeLookUpRight] as? Float,
        let eyeLookDownRight = blendShapes[.eyeLookDownRight] as? Float,
        let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,

        // Left eye blink
        let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,

        // Left eye
        let eyeLookInLeft = blendShapes[.eyeLookInLeft] as? Float,
        let eyeLookOutLeft = blendShapes[.eyeLookOutLeft] as? Float,
        let eyeLookUpLeft = blendShapes[.eyeLookUpLeft] as? Float,
        let eyeLookDownLeft = blendShapes[.eyeLookDownLeft] as? Float,

        // Mouth
        let mouthOpen = blendShapes[.jawOpen] as? Float

        else { return }

      // 2
      // Brow
      let browHeight = (browNode.boundingBox.max.y - browNode.boundingBox.min.y)
      browNode.position.y = neutralBrowY + browHeight * browInnerUp

      // Right eye look
      let rightPupilPos = SCNVector3(x: (neutralRightEyeX - pupilWidth) * (eyeLookInRight - eyeLookOutRight), y: (neutralRightEyeY - pupilHeight) * (eyeLookUpRight - eyeLookDownRight), z: pupilRightNode.position.z)
      pupilRightNode.position = rightPupilPos

      // Right eye blink
      eyeRightNode.scale.y = 1 - eyeBlinkRight

      // Left Eye
      let leftPupilPos = SCNVector3(x: (neutralLeftEyeX - pupilWidth) * (eyeLookOutLeft - eyeLookInLeft), y: (neutralLeftEyeY - pupilHeight) * (eyeLookUpLeft - eyeLookDownLeft), z: pupilLeftNode.position.z)
      pupilLeftNode.position = leftPupilPos

      // Left eye blink
      eyeLeftNode.scale.y = 1 - eyeBlinkLeft

      // Mouth
      mouthNode.position.y = neutralMouthY - mouthHeight * mouthOpen
    }
  }
}
