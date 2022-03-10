//
//  VideoView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/9/22.
//

import SwiftUI
import Photos
import AVKit

struct VideoView: View {
    private var model: PhotoViewModel
    private var videoAsset: PHAsset?
    @State private var player = AVPlayer()
    @State private var videoUrl: URL?
    @State private var playbackRate: Int = 1
    
    init(model: PhotoViewModel, videoAsset: PHAsset?) {
        self.model = model
        self.videoAsset = videoAsset
    }
    
    var body: some View {
        if videoAsset != nil {
            ZoomableScrollView{
                VideoPlayer(player: player)
                    .onAppear(perform: self.loadVideo)
            }
            
            HStack {
                
                Spacer()
                
                Picker("Playback Rate", selection: $playbackRate) {
                    Text("0.005x").tag(-500)
                    Text("0.01x").tag(-100)
                    Text("0.125x").tag(-8)
                    Text("0.25x").tag(-4)
                    Text("0.5x").tag(-2)
                    Text("1x").tag(1)
                    Text("2x").tag(2)
                    Text("4x").tag(4)
                    Text("8x").tag(8)
                }
                .onChange(of: playbackRate, perform: self.handleRateChange)
                .pickerStyle(.menu)
                                
                Spacer()
                
                Button {
                    stepVideo(stepCount: -1)
                } label: {
                    Image(systemName: "arrowtriangle.left.fill")
                }
                .padding()
                
                Spacer()
                
                Button {
                    stepVideo(stepCount: 1)
                } label: {
                    Image(systemName: "arrowtriangle.right.fill")
                }
                .padding()
                
                Spacer()
            }
            
        }
    }
    
    private func loadVideo() {
        if let videoAsset = videoAsset {
            model.getVideo(videoAsset: videoAsset) { videoUrl in
                if let videoUrl = videoUrl {
                    player = AVPlayer(url: videoUrl)
                    player.automaticallyWaitsToMinimizeStalling = false
                    handleRateChange(rateTag: playbackRate)
                }
            }
        }
    }
    
    private func handleRateChange(rateTag: Int) {
        var rate = Float(abs(rateTag))
        if rateTag < 0 {
            rate = 1/rate
        }
        player.rate = rate
    }
    
    private func stepVideo(stepCount: Int) {
        if (stepCount < 0 && player.currentItem?.canStepBackward == true)
            || (stepCount > 0 && player.currentItem?.canStepForward == true) {
            player.currentItem?.step(byCount: stepCount)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(model: PhotoViewModel(), videoAsset: nil)
    }
}
