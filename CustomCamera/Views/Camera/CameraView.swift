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
    @State private var isAnimatingFocus: Bool = false
    @State private var focusTapLocation: CGPoint?
    
    var body: some View {
        VStack {
            ZStack {
                Color(.black)
                    .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    PreviewViewRepresentable(session: model.session)
                        .gesture(createDragGesture(geometry: geometry))
                }
                
                if let tapLocation = focusTapLocation {
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(.yellow, style: StrokeStyle(lineWidth: 1))
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 150, alignment: .center)
                        .scaleEffect(isAnimatingFocus ? 0.5 : 1)
                        .position(x: tapLocation.x, y: tapLocation.y)
                        .onAppear(perform: {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                isAnimatingFocus = true
                            }
                        })
                        .onDisappear(perform: {
                            isAnimatingFocus = false
                        })
                }
                
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
    
    private func createDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                focusTapLocation = value.location
            }
            .onEnded({ _ in
                if let tapLocation = focusTapLocation {
                    let x = min(max(tapLocation.y / geometry.size.height, 0), 1)
                    let y = min(max(1.0 - tapLocation.x / geometry.size.width, 0), 1)
                    let focusPoint = CGPoint(x: x, y: y)
                    
                    model.focusOnPoint(focusPoint: focusPoint)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        focusTapLocation = nil
                    }
                }
            })
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
