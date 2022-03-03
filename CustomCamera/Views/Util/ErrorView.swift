//
//  CameraErrorView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/20/22.
//

import SwiftUI

struct ErrorView: View {
    var error: Error?
    
    var body: some View {
        if let error = self.error {
            Text(error.localizedDescription)
                .bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.red.edgesIgnoringSafeArea(.top))
                .animation(.easeInOut, value: 0.25)
        }
    }
}

struct CameraErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: CameraError.cameraUnavailable)
    }
}
