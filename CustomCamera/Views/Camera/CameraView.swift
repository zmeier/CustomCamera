//
//  CameraView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/20/22.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var model = CameraViewModel()

    var body: some View {
        VStack {
            ZStack {
                Color(.black)
                    .edgesIgnoringSafeArea(.all)
                
                PreviewViewRepresentable(session: model.session)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title)
                            .foregroundColor(.white)
                            .onTapGesture {
                                UIApplication.shared.open(URL(string: "photos-redirect://")!)
                            }
                        Spacer()
                        CaptureButton(isRecording: model.status == .recording)
                            .frame(width: 75, height: 75, alignment: .center)
                            .padding()
                            .disabled(self.isDisabled())
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !self.isDisabled() {
                                    model.toggleMovieRecording()
                                }
                            }
                        Spacer()
                        Image(systemName: "ellipsis.circle")
                            .font(.title)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }

                VStack {
                    ErrorView(error: model.error)
                    Spacer()
                }
            }
        }
    }
    
    private func isDisabled() -> Bool {
        return !(model.status == .ready || model.status == .recording)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
