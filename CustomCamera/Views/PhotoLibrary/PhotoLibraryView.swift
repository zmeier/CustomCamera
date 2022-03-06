//
//  PhotoLibraryView.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/3/22.
//

import SwiftUI
import Photos

struct PhotoLibraryView: View {
    @Binding var isShowPhotoLibrary: Bool
    @StateObject private var model = PhotoViewModel()
    @State private var selectedPhotoAsset: PHAsset?
    @State private var scale: CGFloat = 1

    var columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 2, alignment: .center), count: 4)
    
    var body: some View {
        ZStack {
            if let photoAsset = selectedPhotoAsset {
                ZoomableScrollView{
                    Image(uiImage: model.getImage(photoAsset: photoAsset))
                        .resizable()
                        .scaledToFit()
                }
            } else if let photos = model.allPhotos {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photos, id: \.localIdentifier) { photoAsset in
                            GeometryReader { geometry in
                                Image(uiImage: model.getThumbnail(photoAsset: photoAsset, width: 150, height: 150))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: geometry.size.width)
                                    .onTapGesture {
                                        self.selectedPhotoAsset = photoAsset
                                    }
                            }
                            .clipped()
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.top, 50)
                }
            } else {
                Text(model.error?.errorDescription ?? "Unable to load photos")
            }
            
            VStack {
                HStack {
                    if selectedPhotoAsset == nil {
                        Button("Close") {
                            isShowPhotoLibrary = false
                            scale = 1
                        }
                        .padding(5)
                    } else {
                        Button("Back") {
                            selectedPhotoAsset = nil
                            scale = 1
                        }
                        .padding(5)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
            
        }
    }
}

struct PhotoLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoLibraryView(isShowPhotoLibrary: .constant(true))
    }
}
