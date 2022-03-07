//
//  CameraSettingsView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/27/22.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var model: CameraViewModel
    @State var captureFormat: Int?
    
    var body: some View {
        Form {
            Section(header: Text("Camera")) {
                Picker("Video Camera", selection: $model.selectedDeviceIndex) {
                    ForEach(0..<model.availableDevices.count) { i in
                        Text(model.availableDevices[i].localizedName).tag(Optional.some(i))
                    }
                }
            }
            
            if let captureDeviceFormatLists = buildCaptureDeviceOptions() {
                if captureDeviceFormatLists.count > 0 {
                    ForEach(captureDeviceFormatLists) { captureDeviceFormatList in
                        Section(header: Text("Camera Format - \(captureDeviceFormatList.frameRate) FPS")) {
                            Picker("Format", selection: $model.selectedCaptureDeviceFormat) {
                                ForEach(captureDeviceFormatList.formats) { captureDeviceFormat in
                                    Text(captureDeviceFormat.displayName()).tag(Optional.some(captureDeviceFormat))
                                }
                            }
                            .pickerStyle(InlinePickerStyle())
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func buildCaptureDeviceOptions() -> [CaptureDeviceFormatList] {
        guard let captureDeviceFormats = model.getAvailableVideoCaptureFormats() else {
            return []
        }
        
        var formatOptions: [Double : [CaptureDeviceFormat]] = [:]
        for captureDeviceFormat in captureDeviceFormats {
            if formatOptions[captureDeviceFormat.maxFps] == nil {
                formatOptions[captureDeviceFormat.maxFps] = []
            }
            formatOptions[captureDeviceFormat.maxFps]?.append(captureDeviceFormat)
        }
        
        var captureDeviceFormatViewList: [CaptureDeviceFormatList] = []
        for key in formatOptions.keys.sorted() {
            let captureDevicesForFps = formatOptions[key]!
            let sortedCaptureDeviceForFps = captureDevicesForFps.sorted {
                $0.resolutionWidth < $1.resolutionWidth
            }
            
            let captureDeviceFormatList = CaptureDeviceFormatList(frameRate: Int(key), formats: sortedCaptureDeviceForFps)
            captureDeviceFormatViewList.append(captureDeviceFormatList)
        }
        
        return captureDeviceFormatViewList
    }
}

private struct CaptureDeviceFormatList: Identifiable {
    let id = UUID()
    let frameRate: Int
    let formats: [CaptureDeviceFormat]
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: CameraViewModel())
    }
}
