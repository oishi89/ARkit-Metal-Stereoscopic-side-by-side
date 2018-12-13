//
//  ViewController.swift
//  FirstMetalApp
//
//  Created by NGUYEN, LONG on 11/8/18.
//  Copyright © 2018 NGUYEN, LONG. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import ARKit
import Vision

extension MTKView : RenderDestinationProvider {
}

enum Colors {
    static let clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
}

class ViewController: UIViewController, MTKViewDelegate, ARSessionDelegate {
    
    var session: ARSession!
    var renderer: Renderer!
    
    var rendererLeft: Renderer!
    var rendererRight: Renderer!
    
    public var leftEyeView: MTKView!
    public var rightEyeView: MTKView!
    
    let player: AVPlayer = AVPlayer()
    var playerItem: AVPlayerItem?
    lazy var playerItemVideoOutput: AVPlayerItemVideoOutput = {
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        return AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        session = ARSession()
        session.delegate = self
        
        // Get the video file url.
        guard let url = URL.init(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4") else {
            print("Impossible to find the video.")
            return
        }
        
        // Create an av asset for the given url.
        let asset = AVURLAsset(url: url)
        
        // Create a av player item from the asset.
        playerItem = AVPlayerItem(asset: asset)
        
        // Add the player item video output to the player item.
        playerItem!.add(playerItemVideoOutput)
        
        // Add the player item to the player.
        player.replaceCurrentItem(with: playerItem!)
        
        let ratio = self.view.bounds.width / self.view.bounds.height
        
        let eyeViewsWidth = self.view.bounds.width / 2
        let eyeViewsHeight = min(self.view.bounds.height / ratio + 68, self.view.bounds.height)
        let eyeViewsY = (self.view.bounds.height - eyeViewsHeight) / 2

        leftEyeView = MTKView.init(frame: CGRect.init(x: 0.0, y: eyeViewsY, width: eyeViewsWidth, height: eyeViewsHeight), device: MTLCreateSystemDefaultDevice())
        leftEyeView.clearColor = Colors.clearColor
        leftEyeView.backgroundColor = UIColor.clear
        leftEyeView.delegate = self
        leftEyeView.tag = 1
        
        
        rightEyeView = MTKView.init(frame: CGRect.init(x: eyeViewsWidth, y: eyeViewsY, width: eyeViewsWidth, height: eyeViewsHeight), device: MTLCreateSystemDefaultDevice())
        rightEyeView.backgroundColor = UIColor.clear
        rightEyeView.clearColor = Colors.clearColor
        rightEyeView.delegate = self
        rightEyeView.tag = 2
        
        self.view.addSubview(leftEyeView)
        self.view.addSubview(rightEyeView)
        
        rendererLeft = Renderer(session: session, metalDevice: leftEyeView.device!, renderDestination: leftEyeView)
        
        rendererLeft.drawRectResized(size: leftEyeView.bounds.size)
        
        rendererRight = Renderer(session: session, metalDevice: rightEyeView.device!, renderDestination: rightEyeView)
        
        rendererRight.drawRectResized(size: rightEyeView.bounds.size)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        session.run(configuration)
        player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        session.pause()
        player.pause()
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Create anchor using the camera's current position
        if let currentFrame = session.currentFrame {
            
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.2
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            session.add(anchor: anchor)
        }
    }
    
    private func readBuffer() -> CVPixelBuffer? {
        guard let currentTime = playerItem?.currentTime() else {
            return nil
        }
        
        if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime), let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
            return pixelBuffer
        }
        
        return nil
    }
    
    // MARK: - MTKViewDelegate
    
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        rendererLeft.drawRectResized(size: size)
        rendererRight.drawRectResized(size: size)
    }
    
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        
        let pixelBuffer = readBuffer()
        
        rendererLeft.pixelBuffer = pixelBuffer
        rendererRight.pixelBuffer = pixelBuffer
        rendererLeft.update()
        rendererRight.update()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
