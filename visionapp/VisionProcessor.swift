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

//Creates a DetectedObject using the model with confidence and bounding box
struct DetectedObject: Identifiable, Equatable {
    let id = UUID() // Unique identifier for SwiftUI
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    
    static func == (lhs: DetectedObject, rhs: DetectedObject) -> Bool {
        return lhs.id == rhs.id
    }
}

class VisionProcessor: ObservableObject {
    //Variables to set up model
    private var request: VNCoreMLRequest?
    private var model: VNCoreMLModel?
    
    
    // Motion tracking data (not used currently)
    @Published var velocityData: [(time: Double, value: Double)] = []
    @Published var accelerationData: [(time: Double, value: Double)] = []
    private var previousPosition: CGPoint?
    private var previousTimestamp: Date?
    private var startTime = Date()
    
    
    // Object detection data
    class DetectedObjectsList: ObservableObject {
        @Published var objects: [DetectedObject] = []
    }
    @MainActor @StateObject var detectedObjectsList = DetectedObjectsList()
    
    
    //Initially loads the model
    init() {
        loadObjectDetectionModel()
    }
    
    // Loads the model for general object detection
    
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
        //Gets the individual image frames
        guard let request = self.request else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get image buffer from camera frame")
            return
        }
        
        //Converts image to what model can process
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to convert image buffer to CGImage")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        //Sends images to model to process
        DispatchQueue.global(qos: .default).async {
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
        
        //DispatchQueue - runs on main thread
        DispatchQueue.main.async {
            //Creates a bounding box for the detected object
            let newObjects = results.map { observation in
                DetectedObject(
                    label: observation.labels.first?.identifier ?? "Unknown",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox
                )
            }
            
            //Sends detected objects to UI to update
            if newObjects != self.detectedObjectsList.objects {
                self.objectWillChange.send()
                self.detectedObjectsList.objects = []
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.detectedObjectsList.objects = newObjects
                    //print("✅ UI should now update - detectedObjects count: \(self.detectedObjectsList.objects.count)")
            }
        }
                
        }
        
        //Prints the bounding box for each detected Object
        print("🟦 Detected Objects:")
        for object in results {
            let label = object.labels.first?.identifier ?? "Unknown"
            let confidence = object.confidence
            let boundingBox = object.boundingBox
            print("   - Object: \(label), Confidence: \(confidence), Box: \(boundingBox)")
            //print(" - Bounding Box (normalized): x=\(boundingBox.minX), y=\(boundingBox.minY), w=\(boundingBox.width), h=\(boundingBox.height)")
        }
    }


    // Tracks motion of the selected object (NOT USED CURRENTLY)
    private func trackMotion(of object: VNRecognizedObjectObservation) {
        //Gets bounding box
        let boundingBox = object.boundingBox
        let objectCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let currentTime = Date()

        //Tracks time between where object was previously to current time
        if let previousPos = previousPosition, let previousTime = previousTimestamp {
            let timeInterval = currentTime.timeIntervalSince(previousTime)
            let elapsedTime = currentTime.timeIntervalSince(startTime)

            //Tracks velocity by storing the distance traveled divided by time elapsed
            let dx = objectCenter.x - previousPos.x
            let dy = objectCenter.y - previousPos.y
            let velocity = sqrt(dx * dx + dy * dy) / timeInterval
            let acceleration = (velocity - (sqrt(previousPos.x * previousPos.x + previousPos.y * previousPos.y) / timeInterval)) / timeInterval

            //Stores velocity/motion data
            DispatchQueue.main.async {
                self.velocityData.append((time: elapsedTime, value: velocity))
                self.accelerationData.append((time: elapsedTime, value: acceleration))
            }
        }


        // Store position for next frame tracking
        previousPosition = objectCenter
        previousTimestamp = currentTime
    }
}
