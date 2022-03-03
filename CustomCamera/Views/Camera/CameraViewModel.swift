//
//  CameraViewModel.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/20/22.
//

import UIKit
import AVFoundation

class CameraViewModel: ObservableObject {        
    @Published var error: CameraError?
    @Published var isCameraDisabled: Bool = false
    @Published var status = CameraStatus.unconfigured
    
    let session: AVCaptureSession
    let sessionQueue = DispatchQueue(label: "com.zmeier.SessionQ")
    
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let cameraRecordingOutputDelegate: CameraRecordingOutputDelegate = CameraRecordingOutputDelegate()
    private var captureDevice: AVCaptureDevice?
    
    init() {
        session = AVCaptureSession()
        configureCamera()
    }
    
    func focusOnPoint(focusPoint: CGPoint?) {
        guard let device = captureDevice else {
            print("No capture device found, cannot focus on point.")
            return
        }
        
        guard let focusPoint = focusPoint else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            device.focusPointOfInterest = focusPoint
            device.focusMode = .autoFocus
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = .continuousAutoExposure
            device.unlockForConfiguration()
        }
        catch {
            print("Failed to lock device for focus configuration changes.")
        }
    }
    
    func toggleMovieRecording() {
        cameraRecordingOutputDelegate.setRecordingStatus = { (status: CameraStatus) -> Void in
            self.set(status: status)
        }
        
        sessionQueue.async {
            if !self.movieFileOutput.isRecording {
                if self.status != .ready {
                    print("Camera status \(self.status) is not ready so will not start recording.")
                    return
                }
                
                if UIDevice.current.isMultitaskingSupported {
                    self.cameraRecordingOutputDelegate.backgroundRecordingId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
                
                let availableVideoCodecTypes = self.movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                // Start recording video to a temporary file
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self.cameraRecordingOutputDelegate)
            } else {
                self.movieFileOutput.stopRecording()
            }
        }
    }
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func set(status: CameraStatus) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    private func configureCamera() {
        checkCameraPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession()
            self.session.startRunning()
        }
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.set(error: .deniedAuthorization)
                    self.set(status: .unauthorized)
                }
                self.sessionQueue.resume()
            }
        case .restricted:
            set(error: .restrictedAuthorization)
            set(status: .unauthorized)
        case .denied:
            set(error: .deniedAuthorization)
            set(status: .unauthorized)
        case .authorized:
            break
        @unknown default:
            set(error: .unknownAuthorization)
            set(status: .unauthorized)
        }
    }
    
    private func configureCaptureSession() {
        guard status == .unconfigured else {
            return
        }
        
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        guard let camera = getVideoCaptureDevice() else {
            set(error: .cameraUnavailable)
            set(status: .failed)
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                captureDevice = videoDeviceInput.device
                configureSloMoCaptureDevice(device: captureDevice!)
            } else {
                set(error: .cannotAddInput)
                set(status: .failed)
                return
            }
        } catch {
            set(error: .createCaptureInput(error))
            set(status: .failed)
            return
        }
        
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)
            
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        } else {
            set(error: .cannotAddOutput)
            set(status: .failed)
            return
        }
        
        set(status: .ready)
    }
    
    private func configureSloMoCaptureDevice(device: AVCaptureDevice) {
        var bestFormatOptional: AVCaptureDevice.Format?
        
        for format in device.formats {
            // Check for P3_D65 support.
            guard format.supportedColorSpaces.contains(where: {
                $0 == AVCaptureColorSpace.P3_D65
            }) else {
                continue
            }
            
            // Check for 240 fps
            guard format.videoSupportedFrameRateRanges.contains(where: { range in
                range.maxFrameRate == 240
            }) else {
                continue
            }
            
            // Check for the resolution you want.
            guard format.formatDescription.dimensions.width >= 1280 else { continue }
            guard format.formatDescription.dimensions.height >= 720 else { continue }
            
            bestFormatOptional = format
            
            break // We found a suitable format, no need to keep looking.
        }
        
        guard let bestFormat = bestFormatOptional else { fatalError("No format matching conditions on this device.") }
        
        try! device.lockForConfiguration()
        device.activeFormat = bestFormat
        device.activeColorSpace = .P3_D65
        //        device.exposureMode = .custom
        //        device.setExposureModeCustom(duration: bestFormat.minExposureDuration, iso: bestFormat.maxISO, completionHandler: nil)
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 240)
        device.unlockForConfiguration()
    }
    
    private func getVideoCaptureDevice() -> AVCaptureDevice? {
        if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return backCameraDevice
        } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return dualWideCameraDevice
        } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return dualCameraDevice
        } else if let defaultCameraDevice = AVCaptureDevice.default(for: .video) {
            return defaultCameraDevice
        }
        return nil
    }
}

