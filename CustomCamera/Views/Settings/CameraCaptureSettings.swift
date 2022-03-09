//
//  CameraCaptureSettings.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/7/22.
//

import SwiftUI
import AVFoundation

struct CameraCaptureSettings: View {
    @ObservedObject var settings: CaptureSettings
    
    var columns: [GridItem] = [
        GridItem(.fixed(70), alignment: .leading),
        GridItem(.flexible(), alignment: .leading),
        GridItem(.fixed(70), alignment: .trailing)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8, pinnedViews: .sectionHeaders) {
            
            Toggle("", isOn: $settings.useCustomExposure)
            Text("Customize")
            Color.clear
            
            Text("Shutter")
                .font(.caption)
            Slider(
                value: $settings.logShutter,
                in: log10(settings.minShutter)...log10(settings.maxShutter))
                .disabled(!settings.useCustomExposure)
                .id(settings.useCustomExposure)
            Text("1/\(Int(settings.shutter))")
                .font(.caption)
                .disabled(!settings.useCustomExposure)
            
            Text("ISO")
                .font(.caption)
            Slider(
                value: $settings.iso,
                in: settings.minIso...settings.maxIso,
                step: 1)
                .disabled(!settings.useCustomExposure)
                .id(settings.useCustomExposure)
            Text("\(Int(settings.iso))")
                .font(.caption)
                .disabled(!settings.useCustomExposure)
        }
        .padding(4)
    }
}

struct CameraCaptureSettings_Previews: PreviewProvider {
    static var previews: some View {
        CameraCaptureSettings(settings: CaptureSettings(onUpdate: nil))
    }
}
