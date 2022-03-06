//
//  PhotoLibraryView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/3/22.
//

import SwiftUI
import Photos

struct PhotoLibraryView: View {
    @StateObject private var model = PhotoViewModel()
    @State private var selectedPhotoAsset: PHAsset?
    @State private var scale: CGFloat = 1
    
    var columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 2, alignment: .center), count: 4)
    
    var body: some View {
        ZStack {
            if let photos = model.allPhotos {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photos, id: \.localIdentifier) { photoAsset in
                            GeometryReader { geometry in
                                NavigationLink(
                                    destination: PhotoView(model: model, photoAsset: photoAsset),
                                    label: {
                                        Image(uiImage: model.getThumbnail(photoAsset: photoAsset, width: 150, height: 150))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: geometry.size.width)
                                    })
                            }
                            .clipped()
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            } else {
                Text(model.error?.errorDescription ?? "Unable to load photos")
            }
        }
    }
}

struct PhotoLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoLibraryView()
    }
}
