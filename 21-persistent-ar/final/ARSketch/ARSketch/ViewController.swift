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

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
  
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var sketchButton: UIButton!
  
  @IBOutlet weak var mappingStatusLabel: UILabel!
  @IBOutlet weak var sessionInfoView: UIVisualEffectView!
  @IBOutlet weak var sessionInfoLabel: UILabel!
  
  @IBOutlet weak var saveExperienceButton: StatusControlledButton!
  @IBOutlet weak var loadExperienceButton: StatusControlledButton!
  
  @IBOutlet weak var snapshotThumbnailImageView: UIImageView!
  @IBOutlet weak var resetSceneButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  
  fileprivate var previousPoint: SCNVector3?
  let lineColor = UIColor.white
  
  var isSketchButtonPressed = false
  var viewCenter: CGPoint?
  
  var defaultConfiguration: ARWorldTrackingConfiguration {
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    configuration.environmentTexturing = .automatic
    return configuration
  }
  
  lazy var mapSaveURL: URL = {
    do {
      return try FileManager.default
        .url(for: .documentDirectory,
             in: .userDomainMask,
             appropriateFor: nil,
             create: true)
        .appendingPathComponent("mymap.arexperience")
    } catch {
      fatalError("Can't get file save URL: \(error.localizedDescription)")
    }
  }()
  
  var mapDataFromFile: Data? {
    return try? Data(contentsOf: mapSaveURL)
  }
  var isRelocalizingMap = false
  
  // MARK: - View Life Cycle
  
  // Lock the orientation of the app to the orientation in which it is launched
  override var shouldAutorotate: Bool {
    return false
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let viewBounds = self.view.bounds
    viewCenter = CGPoint(x: viewBounds.width / 2.0, y: viewBounds.height / 2.0)
    if mapDataFromFile != nil {
      self.loadExperienceButton.isEnabled = true
    } else {
      self.loadExperienceButton.isEnabled = false
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    sceneView.delegate = self
    sceneView.session.delegate = self
    sceneView.session.run(defaultConfiguration)
    
    // Prevent the screen from being dimmed after a while as users will likely
    // have long periods of interaction without touching the screen or buttons.
    UIApplication.shared.isIdleTimerDisabled = true
    
    //hide buttons
    saveExperienceButton.isHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  // MARK: - Place AR content
  var count = 0
  var currentLineAnchorName : String?
  var lineObjectAnchors = [ARLineAnchor]()
  
  func addLineAnchorForObject(sourcePoint: SCNVector3?,
                              destinationPoint: SCNVector3?) {
    guard let hitTestResult = sceneView
      .hitTest(self.viewCenter!, types: [.existingPlaneUsingGeometry,
                                         .estimatedHorizontalPlane])
      .first
      else { return }
    currentLineAnchorName = "virtualObject\(count)"
    count = count+1
    let lineAnchor = ARLineAnchor(name: currentLineAnchorName!,
                                  transform: hitTestResult.worldTransform,
                                  sourcePoint: sourcePoint,
                                  destinationPoint: destinationPoint)
    sceneView.session.add(anchor: lineAnchor)
    lineObjectAnchors.append(lineAnchor)
  }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    DispatchQueue.main.async {
      self.isSketchButtonPressed = self.sketchButton.isHighlighted
    }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    guard let pointOfView = sceneView.pointOfView else { return }
    let transform = pointOfView.transform
    let direction = SCNVector3(-1 * transform.m31, -1 * transform.m32, -1 * transform.m33)
    let currentPoint = pointOfView.position + (direction * 0.1)
    if isSketchButtonPressed {
      if let previousPoint = previousPoint {
        addLineAnchorForObject(sourcePoint: previousPoint,
                               destinationPoint: currentPoint)
      }
    }
    previousPoint = currentPoint
  }
  
  func renderer(_ renderer: SCNSceneRenderer,
                didAdd node: SCNNode,
                for anchor: ARAnchor) {
    let lineARAnchor = anchor as? ARLineAnchor
    if let lineAnchor = lineARAnchor,
      let source = lineAnchor.sourcePoint,
      let destination = lineAnchor.sourcePoint {
      lineObjectAnchors.append(lineAnchor)
      let lineNode = SCNLineNode(from: source,
                                 to: destination,
                                 radius: 0.02,
                                 color: lineColor)
      node.addChildNode(lineNode)
    }
  }
}

// MARK: - AR session management
extension ViewController: ARSessionDelegate {
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay.
    sessionInfoLabel.text = "Session was interrupted"
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required.
    sessionInfoLabel.text = "Session interruption ended"
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user.
    sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    switch frame.worldMappingStatus {
    case .extending, .mapped:
      if let lastLineAnchor = lineObjectAnchors.last,
        lineObjectAnchors.count > 0 && frame.anchors.contains(lastLineAnchor) {
        saveExperienceButton.isEnabled = true
        saveExperienceButton.isHidden = false
      }
    default:
      saveExperienceButton.isHidden = true
      saveExperienceButton.isEnabled = false
    }
    mappingStatusLabel.text = """
    Mapping: \(frame.worldMappingStatus.description)
    Tracking: \(frame.camera.trackingState.description)
    """
    updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
  }
  
  func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
    return true
  }
  
  func session(_ session: ARSession,
               cameraDidChangeTrackingState camera: ARCamera) {
    updateSessionInfoLabel(for: session.currentFrame!,
                           trackingState: camera.trackingState)
  }
}

// MARK: - Persistent AR
extension ViewController {
  func getWorldMap() -> ARWorldMap {
    guard let data = mapDataFromFile else {
      fatalError("""
                 Map data should already be verified to exist
                 before Load button is enabled.
                 """)
    }
    do {
      guard let worldMap =
        try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self,
                                               from: data)
        else {
          fatalError("No ARWorldMap in archive.")
      }
      return worldMap
    } catch {
      fatalError("Can't unarchive ARWorldMap from file data: \(error)")
    }
  }
  
  @IBAction func resetTracking(_ sender: UIButton?) {
    sceneView.session.run(defaultConfiguration,
                          options: [.resetTracking, .removeExistingAnchors])
    isRelocalizingMap = false
    lineObjectAnchors.removeAll()
  }
  
  @IBAction func saveExperience(_ sender: UIButton) {
    sceneView.session.getCurrentWorldMap { worldMap, error in
      guard let map = worldMap else {
        self.showAlert(title: "Can't get current world map",
                       message: error!.localizedDescription)
        return
      }
      guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView) else {
        fatalError("Can't take snapshot")
      }
      map.anchors.append(snapshotAnchor)
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: map,
                                                    requiringSecureCoding: true)
        try data.write(to: self.mapSaveURL, options: [.atomic])
        DispatchQueue.main.async {
          self.loadExperienceButton.isHidden = false
          self.loadExperienceButton.isEnabled = true
        }
      } catch {
        fatalError("Can't save map: \(error.localizedDescription)")
      }
    }
  }
  
  @IBAction func loadExperience(_ sender: Any) {
    let worldMap: ARWorldMap = getWorldMap()
    if let snapshotData = worldMap.snapshotAnchor?.imageData,
      let snapshot = UIImage(data: snapshotData) {
      self.snapshotThumbnailImageView.image = snapshot
    } else {
      print("No snapshot image in world map")
    }
    worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
    
    let configuration = self.defaultConfiguration
    configuration.initialWorldMap = worldMap
    sceneView.session.run(configuration,
                          options: [.resetTracking, .removeExistingAnchors])
    
    isRelocalizingMap = true
    lineObjectAnchors.removeAll()
  }
  
  private func updateSessionInfoLabel(for frame: ARFrame,
                                      trackingState: ARCamera.TrackingState) {
    let message: String
    snapshotThumbnailImageView.isHidden = true
    switch (trackingState, frame.worldMappingStatus) {
    case (.normal, .mapped),
         (.normal, .extending):
      if frame.anchors.contains(where: { $0.name == "virtualObject0" }) {
        message = "Tap 'Save Experience' to save the current map."
      } else {
        message = "Tap Sketch to draw something."
      }
    case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
      message = """
      Move around to map the environment
      or tap 'Load Experience' to load a saved experience.
      """
    case (.normal, _) where mapDataFromFile == nil:
      message = "Move around to map the environment."
    case (.limited(.relocalizing), _) where isRelocalizingMap:
      message = "Move your device to the location shown in the image."
      snapshotThumbnailImageView.isHidden = false
    default:
      message = trackingState.localizedFeedback
    }
    sessionInfoLabel.text = message
    sessionInfoView.isHidden = message.isEmpty
  }
  
  @IBAction func shareWorldMap(_ sender: Any) {
  }
}
