//
//  PhotoView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/5/22.
//

import SwiftUI
import Photos

struct PhotoView: View {
    var model: PhotoViewModel
    var photoAsset: PHAsset?
    
    var body: some View {
        if let photoAsset = photoAsset {
            ZoomableScrollView{
                Image(uiImage: model.getImage(photoAsset: photoAsset))
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoView(model: PhotoViewModel(), photoAsset: nil)
    }
}
