//
//  CaptureButton.swift
//  CustomCamera
//
//  Created by Zachary Meier on 2/20/22.
//

import SwiftUI

struct CaptureButton: View {
    @Environment(\.isEnabled) private var isEnabled
    var isRecording: Bool
    @State private var isAnimatingRecordStateChange: Bool = false
    @State private var isAnimatingRecording: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .strokeBorder(isEnabled ? .white : .gray, lineWidth: geometry.size.width / 30)
                if isRecording {
                    RoundedRectangle(cornerRadius: geometry.size.width / 10)
                        .aspectRatio(1.0, contentMode: .fit)
                        .foregroundColor(isEnabled ? .red : .gray)
                        .frame(width: geometry.size.width / 3, height: geometry.size.width / 3, alignment: .center)
                        .scaleEffect(isAnimatingRecordStateChange ? 2 : isAnimatingRecording ? 1.15 : 1)
                        .onAppear(perform: {
                            isAnimatingRecording = true
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                                isAnimatingRecording = false
                            }
                        })
                } else {
                    Circle()
                        .foregroundColor(isEnabled ? .red : .gray)
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8, alignment: .center)
                        .scaleEffect(isAnimatingRecordStateChange ? 0.5 : 1)
                }
            }
            .onChange(of: isRecording) { _ in
                isAnimatingRecordStateChange = true
                withAnimation(Animation.easeInOut(duration: 0.5)) {
                    isAnimatingRecordStateChange = false
                }
            }
        }
    }
}

struct CaptureButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.black)
                .edgesIgnoringSafeArea(.all)
            CaptureButton(isRecording: true)
        }
    }
}
