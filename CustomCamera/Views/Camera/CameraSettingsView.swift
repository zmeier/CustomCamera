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
            Form {
                Section(header: Text("Camera")) {
                        
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct CameraSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettingsView()
    }
}
