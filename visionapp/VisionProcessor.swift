//
//  VisionProcessor.swift
//  visionapp
//
//  Created by Sophia Buda on 1/31/25.
//

import Vision
import AVFoundation
import CoreML
import SwiftUI

struct DetectedObject: Identifiable {
    let id = UUID() // Unique identifier for SwiftUI
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}

class VisionProcessor: ObservableObject {
    private var request: VNCoreMLRequest?
    private var model: VNCoreMLModel?
    
    
    // Motion tracking data
    @Published var velocityData: [(time: Double, value: Double)] = []
    @Published var accelerationData: [(time: Double, value: Double)] = []
    private var previousPosition: CGPoint?
    private var previousTimestamp: Date?
    private var startTime = Date()
    
    
    // Object detection data
    @Published var detectedObjects: [DetectedObject] = []
    // @Published var selectedObject: VNRecognizedObjectObservation?
    
    
    init() {
        loadObjectDetectionModel()
    }
    
    // Loads the MobileNetV2 model for general object detection
    
    private func loadObjectDetectionModel() {
        print("📢 Loading Yolov3 model for object detection")

        do {
            let coreMLModel = try YOLOv3(configuration: MLModelConfiguration()).model
            self.model = try VNCoreMLModel(for: coreMLModel)
            self.request = VNCoreMLRequest(model: self.model!, completionHandler: visionRequestDidComplete)

            // Ensure image is correctly cropped
            self.request?.imageCropAndScaleOption = .centerCrop

            print("✅ Model loaded successfully")
        } catch {
            print("❌ Failed to load model: \(error.localizedDescription)")
        }
    }
 
    
    // Processes a frame from the camera
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let request = self.request else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get image buffer from camera frame")
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to convert image buffer to CGImage")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
            }
        }
    }


    // Handles Vision's object detection results
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let error = error {
            print("❌ Vision request failed: \(error.localizedDescription)")
            return
        }

        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }

        DispatchQueue.main.async {
            self.objectWillChange.send()
            if !results.isEmpty {
                self.detectedObjects = results.map { observation in
                    DetectedObject( label: observation.labels.first?.identifier ?? "Unknown",
                                    confidence: observation.confidence,
                                    boundingBox: observation.boundingBox
                    )
                }
            }
            
            if results.isEmpty {
                // print("❌ No objects detected in the frame")
            } else {
                print("🟦 Detected Objects:")
                for object in results {
                    let label = object.labels.first?.identifier ?? "Unknown"
                    let confidence = object.confidence
                    let boundingBox = object.boundingBox
                    print("   - Object: \(label), Confidence: \(confidence), Box: \(boundingBox)")
                    print(" - Bounding Box (normalized): x=\(boundingBox.minX), y=\(boundingBox.minY), w=\(boundingBox.width), h=\(boundingBox.height)")
                }
            }
        }
    }


    // Tracks motion of the selected object
    private func trackMotion(of object: VNRecognizedObjectObservation) {
        let boundingBox = object.boundingBox
        let objectCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let currentTime = Date()


        if let previousPos = previousPosition, let previousTime = previousTimestamp {
            let timeInterval = currentTime.timeIntervalSince(previousTime)
            let elapsedTime = currentTime.timeIntervalSince(startTime)


            let dx = objectCenter.x - previousPos.x
            let dy = objectCenter.y - previousPos.y
            let velocity = sqrt(dx * dx + dy * dy) / timeInterval
            let acceleration = (velocity - (sqrt(previousPos.x * previousPos.x + previousPos.y * previousPos.y) / timeInterval)) / timeInterval


            DispatchQueue.main.async {
                self.velocityData.append((time: elapsedTime, value: velocity))
                self.accelerationData.append((time: elapsedTime, value: acceleration))
            }
        }


        // Store position for next frame tracking
        previousPosition = objectCenter
        previousTimestamp = currentTime
    }


    // Allows user to select an object by tapping
//    func selectObject(at point: CGPoint, screenSize: CGSize) {
//        let tappedPoint = CGPoint(x: point.x / screenSize.width, y: 1 - (point.y / screenSize.height)) // Convert coordinate system
//
//        DispatchQueue.main.async {
//            print("Tap at: \(tappedPoint)")
//            
//            for object in self.detectedObjects {
//                let boundingBox = object.boundingBox
//                print("Checking Object: \(object.labels.first?.identifier ?? "Unknown"), Box: \(boundingBox)")
//                
//                if object.boundingBox.contains(tappedPoint) {
//                    self.selectedObject = object
//                    print("Selected object: \(object.labels.first?.identifier ?? "Unknown")")
//                    return
//                }
//            }
//            print("No object found at tap location")
//        }
//    }
}
