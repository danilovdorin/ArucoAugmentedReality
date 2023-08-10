//
//  VNViewController.swift
//  ARUcoTest
//
//  Created by Dorin Danilov on 25/07/2018.
//  Copyright © 2018 HHCC. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import SceneKit

//new 1

class VNViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sceneView: SCNView!
    
    var cameraNode: SCNNode!
    private var boxNode: SCNNode!
    
    @IBOutlet weak var previewView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var session: AVCaptureSession!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startCamera()
        initSceneKit()
    }
    
    func initSceneKit() {
        // create a new scene
        
        let scene = SCNScene()
        
        // create and add a camera to the scene
        cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zFar = 1000
        camera.zNear = 0.1
        cameraNode.camera = camera
        
        scene.rootNode.addChildNode(cameraNode)
        
        //retrieve the SCNView
        let scnView = sceneView!
        
        // set the scene to the view
        scnView.scene = scene
        
        scnView.autoenablesDefaultLighting = true
        
        // configure the view
        scnView.backgroundColor = UIColor.clear
        
        let box = SCNBox(width: 10, height: 10 , length: 10, chamferRadius: 0)
        boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0,0,0)
        
        
        scene.rootNode.addChildNode(boxNode)
        
        sceneView.pointOfView = cameraNode
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            previewLayer.frame = previewView.bounds
        }
    }
    
    private func startCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { status in
            if status {
                DispatchQueue.main.async(execute: {
                    self.initCamera()
                })
            } else {
                
            }
        }
    }
    
    func initCamera() {
        let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: AVCaptureDevice.Position.back)
        let deviceInput = try! AVCaptureDeviceInput(device: device!)
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSession.Preset.iFrame960x540
        self.session.addInput(deviceInput)
        let sessionOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()

        let outputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])
        sessionOutput.setSampleBufferDelegate(self, queue: outputQueue)
        self.session.addOutput(sessionOutput)
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.backgroundColor = UIColor.black.cgColor
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        self.previewView.layer.addSublayer(self.previewLayer)
        
        self.session.startRunning()
        view.setNeedsLayout()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!

        
        //QR detection
        guard let transQR = OpenCVWrapper.arucoTransformMatrix(from: pixelBuffer) else {

            DispatchQueue.main.async(execute: {
                self.boxNode.isHidden = true
            })
            
            return
        }

        DispatchQueue.main.async(execute: {
            self.imageView.image = transQR.image

            self.boxNode.isHidden = false
           
            self.setCameraMatrix(transQR)
        })
    }
    
    func setCameraMatrix(_ transformModel:  TransformModel) {
        
        print(transformModel.transform.description)
        
        cameraNode.rotation = transformModel.rotationVector
        cameraNode.position = transformModel.translationVector
        
//        cameraNode.transform = transformModel.transform
        
        print("position: \(cameraNode.position.x) \(cameraNode.position.y) \(cameraNode.position.z)")
    }
    
}

extension SCNMatrix4 {
    var description: String {
        get {
            return "\(m11) \(m12) \(m13) \(m14) \n" +
                    "\(m21) \(m22) \(m23) \(m24) \n" +
                    "\(m31) \(m32) \(m33) \(m34) \n" +
                    "\(m41) \(m42) \(m43) \(m44) \n"
        }
    }
}
