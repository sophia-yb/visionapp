//
//  ContentView.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import SwiftUI
import AVFoundation


struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()


    var body: some View {
        ZStack {
            // Camera feed
            if let previewLayer = cameraManager.previewLayer {
                CameraPreview(previewLayer: previewLayer)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .edgesIgnoringSafeArea(.all) // Ensure full-screen display
            } else {
                Text("Camera not available")
                    .foregroundColor(.red)
            }


            // Overlay: Show camera state
            VStack {
                Spacer()
                Text(cameraManager.isCameraRunning ? "Camera Running" : "Camera Stopped")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
            }
        }
        .onAppear {
            Task {
                await cameraManager.setUpCaptureSession()
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}


//#Preview {
//    ContentView()
//}

