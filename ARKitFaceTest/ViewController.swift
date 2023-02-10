//
//  ViewController.swift
//  ARKitFaceTest
//
//  Created by bo cui on 2023/2/9.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController  {
    
    var sceneView: ARSCNView!
    var anchorNode: SCNNode?
    var mask: Mask?
    var maskType = MaskType.painted//MaskType.basic
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        createFaceGeometry()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTracking()
    }
    
    @IBAction func didTapMask(_ sender: Any) {
        switch maskType {
        case .basic:
            maskType = .painted
        case .painted:
            maskType = .basic
        }
        
        mask?.swapMaterials(maskType: maskType)
        resetTracking()
    }
    
    func setupScene() {
        // Set the view's delegate
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.insertSubview(self.sceneView, at: 0)
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Setup environment
        sceneView.automaticallyUpdatesLighting = true /* default setting */
        sceneView.autoenablesDefaultLighting = false /* default setting */
        sceneView.scene.lightingEnvironment.intensity = 1.0 /* default setting */
    }
    
    func resetTracking() {
        guard ARConfiguration.isSupported, ARFaceTrackingConfiguration.isSupported else{
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true /* default setting */
        configuration.providesAudioData = false /* default setting */
        configuration.isWorldTrackingEnabled = false /* default setting */
        configuration.maximumNumberOfTrackedFaces = 1 /* default setting */
        sceneView.session.run(configuration, options: [.removeExistingAnchors,.resetTracking])
    }
    
    // Create ARSCNFaceGeometry
    func createFaceGeometry() {
        let device = sceneView.device!
        let maskGeometry = ARSCNFaceGeometry(device: device)!
        mask = Mask(geometry: maskGeometry, maskType: maskType)
    }
    
    // Setup Face Content Nodes
    func setupFaceNodeContent() {
        guard let node = anchorNode else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
        if let content = mask {
            node.addChildNode(content)
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // SceneKit Renderer
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = session.currentFrame?.lightEstimate else {
            return
        }
        let intensity = estimate.ambientIntensity / 1000.0
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    // ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        anchorNode = node
        setupFaceNodeContent()
    }
    
    // ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        mask?.update(withFaceAnchor: faceAnchor)
    }
    
    // ARSession Handling
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("** didFailWithError")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("** sessionWasInterrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("** sessionInterruptionEnded")
    }
}


enum MaskType: Int {
    case basic
    case painted
}

class Mask: SCNNode {
    init(geometry: ARSCNFaceGeometry, maskType: MaskType) {
        super.init()
        self.geometry = geometry
        self.swapMaterials(maskType: maskType)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: Materials Setup
    func swapMaterials(maskType: MaskType) {
        // 1
        guard let material = geometry?.firstMaterial! else { return }
        material.lightingModel = .physicallyBased
        
        // 2
        // Reset materials
        material.diffuse.contents = nil
        material.normal.contents = nil
        material.transparent.contents = nil
        
        // 3
        switch maskType {
        case .basic:
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.0,
                                                green: 0.68,
                                                blue: 0.37,
                                                alpha: 1)
        case .painted:
            material.diffuse.contents = UIImage(named: "face")
        }
    }
    
    // ARFaceAnchor Update
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
}
