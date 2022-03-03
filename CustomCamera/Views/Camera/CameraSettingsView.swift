//
//  CameraSettingsView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/27/22.
//

import SwiftUI

struct CameraSettingsView: View {
    @State private var val = 50.0
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            Slider(
                value: $val,
                in: 0...100,
                step: 5,
                onEditingChanged: { editing in
                    isEditing = editing
                }
            )
        }
    }
}

struct CameraSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettingsView()
    }
}
