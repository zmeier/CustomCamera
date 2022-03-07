//
//  CaptureDevice.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/6/22.
//

import AVFoundation

struct CaptureDeviceFormat: Identifiable, Codable {
    var id = UUID()
    let resolutionWidth: Int32
    let resolutionHeight: Int32
    let maxFps: Double
    
    func displayName() -> String {
        return "\(resolutionWidth)x\(resolutionHeight) @\(Int(maxFps)) FPS"
    }
}

extension CaptureDeviceFormat: Hashable {
    static func == (lhs: CaptureDeviceFormat, rhs: CaptureDeviceFormat) -> Bool {
        return lhs.resolutionWidth == rhs.resolutionWidth
        && lhs.resolutionHeight == rhs.resolutionHeight
        && lhs.maxFps == rhs.maxFps
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(resolutionWidth)
        hasher.combine(resolutionHeight)
        hasher.combine(maxFps)
    }
}
