//
//  CameraViewModelDelegate.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/27/22.
//

import UIKit
import AVFoundation
import CoreLocation
import Photos
import SwiftUI

class CameraRecordingOutputDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var setRecordingStatus: ((_: CameraStatus) -> ())?
    var backgroundRecordingId: UIBackgroundTaskIdentifier?
    
    private var locationManager = CLLocationManager()
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            if let setRecordingStatus = self.setRecordingStatus {
                setRecordingStatus(.recording)
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            DispatchQueue.main.async {
                if let setRecordingStatus = self.setRecordingStatus {
                    setRecordingStatus(.ready)
                }
            }
        }
        
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if let currentBackgroundRecordingId = backgroundRecordingId {
                backgroundRecordingId = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingId != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingId)
                }
            }
        }
        
        DispatchQueue.main.async {
            if let setRecordingStatus = self.setRecordingStatus {
                setRecordingStatus(.processing)
            }
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // Check the authorization status
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                        
                        // Specify the location the movie was recorded
                        creationRequest.location = self.locationManager.location
                    }, completionHandler: { success, error in
                        if !success {
                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }
    }
}
