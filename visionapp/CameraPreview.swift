//
//  ContentPreview.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import SwiftUI
import AVFoundation


struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer


    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }


    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            self.previewLayer.frame = uiView.bounds
        }
    }
}
