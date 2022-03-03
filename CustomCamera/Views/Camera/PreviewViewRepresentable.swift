//
//  CameraViewRepresentable.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/27/22.
//

import SwiftUI
import AVFoundation

struct PreviewViewRepresentable: UIViewRepresentable {
    typealias UIViewType = PreviewView
        
    var session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIViewType {
        let uiView = PreviewView()
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.videoGravity = .resizeAspectFill
            uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
            uiView.videoPreviewLayer.session = session
        }
        return uiView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
