//
//  CaptureSettings.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/7/22.
//

import Foundation

class CaptureSettings: ObservableObject {
    @Published var useCustomExposure: Bool {
        didSet {
            if useCustomExposure != oldValue {
                self.onUpdate?()
            }
        }
    }
    var minShutter: Float
    var maxShutter: Float
    @Published var shutter: Float {
        didSet {
            if shutter != oldValue {
                logShutter = log10(shutter)
                self.onUpdate?()
            }
        }
    }
    @Published var logShutter: Float {
        didSet {
            if logShutter != oldValue {
                shutter = powf(10.0, logShutter)
            }
        }
    }
    var minIso: Float
    var maxIso: Float
    @Published var iso: Float {
        didSet {
            if iso != oldValue {
                self.onUpdate?()
            }
        }
    }
    var onUpdate: (() -> ())?
    
    init(useCustomExposure: Bool? = false,
         minShutter: Float? = 1,
         maxShutter: Float? = 1000,
         shutter: Float? = 250,
         minIso: Float? = 25,
         maxIso: Float? = 960,
         iso: Float? = 960,
         onUpdate: (() -> ())?) {
        self.useCustomExposure = useCustomExposure!
        self.shutter = shutter!
        self.logShutter = log10(shutter!)
        self.minShutter = minShutter!
        self.maxShutter = maxShutter!
        self.iso = iso!
        self.minIso = minIso!
        self.maxIso = maxIso!
        self.onUpdate = onUpdate
    }
}
