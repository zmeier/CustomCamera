//
//  CameraViewModel.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/20/22.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewModel: ObservableObject {
    private static let SELECTED_CAMERA_DEFAULT_KEY = "SelectedCameraDevice"
    private static let SELECTED_CAMERA_FORMAT_DEFAULT_KEY = "SelectedCameraDeviceFormat"
    
    @Published var error: CameraError?
    @Published var isCameraDisabled: Bool = false
    @Published var status = CameraStatus.unconfigured
    @Published var availableDevices: [AVCaptureDevice]
    @Published var selectedDeviceIndex: Int? {
        didSet {
            if selectedDeviceIndex != oldValue {
                if let index = selectedDeviceIndex {
                    captureDevice = availableDevices[index]
                } else {
                    captureDevice = nil
                }
                
                self.sessionQueue.async {
                    self.configureCaptureSession()
                }
            }
        }
    }
    @Published var selectedCaptureDeviceFormat: CaptureDeviceFormat? {
        didSet {
            if selectedCaptureDeviceFormat != oldValue {
                if let dataToSave = selectedCaptureDeviceFormat {
                    let encodedData = try? JSONEncoder().encode(dataToSave)
                    self.defaults.set(encodedData, forKey: CameraViewModel.SELECTED_CAMERA_FORMAT_DEFAULT_KEY)
                }
                self.sessionQueue.async {
                    self.updateFormatConfiguration()
                }
            }
        }
    }
    @Published var captureSettings: CaptureSettings = CaptureSettings(onUpdate: nil)
    
    let session: AVCaptureSession
    let sessionQueue = DispatchQueue(label: "com.zmeier.SessionQ")
    
    private var captureDevice: AVCaptureDevice? {
        didSet {
            handleCaptureDeviceUpdated()
        }
    }
    
    private let defaults = UserDefaults.standard
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let cameraRecordingOutputDelegate: CameraRecordingOutputDelegate = CameraRecordingOutputDelegate()
    
    init() {
        session = AVCaptureSession()
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                                    [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
                                                                mediaType: .video, position: .unspecified)
        availableDevices = discoverySession.devices
        let selectedCamera = defaults.string(forKey: CameraViewModel.SELECTED_CAMERA_DEFAULT_KEY)
        
        if availableDevices.count == 0 {
            selectedDeviceIndex = nil
        } else {
            selectedDeviceIndex = 0
            if let selectedCamera = selectedCamera {
                for i in 0..<availableDevices.count {
                    if availableDevices[i].uniqueID == selectedCamera {
                        selectedDeviceIndex = i
                        if let data = defaults.object(forKey: CameraViewModel.SELECTED_CAMERA_FORMAT_DEFAULT_KEY) as? Data {
                            selectedCaptureDeviceFormat = try? JSONDecoder().decode(CaptureDeviceFormat.self, from: data)
                        }
                        break
                    }
                }
            }
        }
        
        if let index = selectedDeviceIndex {
            captureDevice = availableDevices[index]
            handleCaptureDeviceUpdated()
        } else {
            captureDevice = nil
        }
        
        configureCamera()
        
        captureSettings.onUpdate = self.updateDeviceCaptureSettings
    }
    
    func getAvailableVideoCaptureFormats() -> Set<CaptureDeviceFormat>? {
        guard let captureDevice = captureDevice else {
            return nil
        }
        
        var captureDeviceFormats = Set<CaptureDeviceFormat>()
        for format in captureDevice.formats {
            if let captureDeviceFormat = getCaptureDeviceFormat(for: format) {
                captureDeviceFormats.insert(captureDeviceFormat)
            }
        }
        
        return captureDeviceFormats
    }
    
    func focusOnPoint(focusPoint: CGPoint?) {
        guard let device = captureDevice else {
            print("No capture device found, cannot focus on point.")
            return
        }
        
        if !device.isFocusPointOfInterestSupported {
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
            device.unlockForConfiguration()
            captureSettings.useCustomExposure = false
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
            self.updateFormatConfiguration()
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
        set(error: nil)
        set(status: .unconfigured)
        
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        guard let camera = captureDevice else {
            set(error: .cameraUnavailable)
            set(status: .failed)
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                defaults.set(videoDeviceInput.device.uniqueID, forKey: CameraViewModel.SELECTED_CAMERA_DEFAULT_KEY)
            } else {
                set(error: .cannotAddInput)
                set(status: .failed)
                defaults.set(nil, forKey: CameraViewModel.SELECTED_CAMERA_DEFAULT_KEY)
                return
            }
        } catch {
            set(error: .createCaptureInput(error))
            set(status: .failed)
            defaults.set(nil, forKey: CameraViewModel.SELECTED_CAMERA_DEFAULT_KEY)
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
    
    private func updateFormatConfiguration() {
        guard let device = captureDevice else {
            print("Cannot update format configuration as no device is currently configured")
            return
        }
        
        if selectedCaptureDeviceFormat == nil {
            return
        }
        
        var bestFormat: AVCaptureDevice.Format?
        for format in device.formats {
            if let captureDeviceFormat = getCaptureDeviceFormat(for: format) {
                if captureDeviceFormat == selectedCaptureDeviceFormat {
                    bestFormat = format
                    break
                }
            }
        }
        
        guard let bestFormat = bestFormat else {
            print("Could not find a format matching the current selected format")
            return
        }
        
        try! device.lockForConfiguration()
        device.activeFormat = bestFormat
        device.activeColorSpace = .P3_D65
        if let maxFrameRate = getMaxFrameRate(for: bestFormat) {
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(maxFrameRate))
        }
        device.unlockForConfiguration()
        
        captureSettings.minShutter = Float(bestFormat.maxExposureDuration.timescale)
        captureSettings.maxShutter = Float(bestFormat.minExposureDuration.timescale)
        captureSettings.minIso = bestFormat.minISO
        captureSettings.maxIso = bestFormat.maxISO
    }
    
    private func getCaptureDeviceFormat(for format: AVCaptureDevice.Format) -> CaptureDeviceFormat? {
        guard format.supportedColorSpaces.contains(where: {
            $0 == AVCaptureColorSpace.P3_D65
        }) else {
            return nil
        }
        
        guard let maxFrameRate = getMaxFrameRate(for: format) else {
            return nil
        }
        
        return CaptureDeviceFormat(
            resolutionWidth: format.formatDescription.dimensions.width,
            resolutionHeight: format.formatDescription.dimensions.height,
            maxFps: maxFrameRate
        )
    }
    
    private func getMaxFrameRate(for format: AVCaptureDevice.Format) -> Double? {
        return format.videoSupportedFrameRateRanges.max {
            $0.maxFrameRate < $1.maxFrameRate
        }.map {
            $0.maxFrameRate
        }
    }
    
    private func updateDeviceCaptureSettings() {
        guard let device = captureDevice else {
            print("Cannot find capture device to update")
            return
        }
        
        try! device.lockForConfiguration()
        defer {
            device.unlockForConfiguration()
        }
        
        if captureSettings.useCustomExposure {
            device.exposureMode = .custom
        } else {
            device.exposureMode = .continuousAutoExposure
        }
        
        if device.exposureMode == .custom {
            var shutter = CMTime(value: 1, timescale: CMTimeScale(captureSettings.shutter))
            if shutter < device.activeFormat.minExposureDuration {
                shutter = device.activeFormat.minExposureDuration
            } else if shutter > device.activeFormat.maxExposureDuration {
                shutter = device.activeFormat.maxExposureDuration
            }
            
            var iso = captureSettings.iso
            if iso < device.activeFormat.minISO {
                iso = device.activeFormat.minISO
            } else if iso > device.activeFormat.maxISO {
                iso = device.activeFormat.maxISO
            }
            
            device.setExposureModeCustom(duration: shutter, iso: iso, completionHandler: nil)
        }
    }
    
    private func handleCaptureDeviceUpdated() {
        if let captureDevice = captureDevice {
            captureSettings.useCustomExposure = captureDevice.exposureMode == .custom
            captureSettings.shutter = Float(captureDevice.exposureDuration.timescale)
            captureSettings.iso = Float(captureDevice.iso)
        } else {
            captureSettings.useCustomExposure = false
        }
    }
}
