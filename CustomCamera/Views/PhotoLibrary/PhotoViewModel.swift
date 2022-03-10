//
//  PhotoViewModel.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/3/22.
//

import Photos
import UIKit

class PhotoViewModel: ObservableObject {
    @Published var error: AuthorizationError?
    @Published var allPhotos: PHFetchResultCollection?
    
    private let imageManager = PHCachingImageManager.default()
    
    init() {
        checkPermissions()
    }
    
    func getThumbnail(photoAsset: PHAsset, width: CGFloat, height: CGFloat) -> UIImage {
        return loadImage(photoAsset: photoAsset, targetSize: CGSize(width: width, height: height))
    }
    
    func getImage(photoAsset: PHAsset) -> UIImage {
        return loadImage(photoAsset: photoAsset, targetSize: PHImageManagerMaximumSize)
    }
    
    func getVideo(videoAsset: PHAsset, completionHandler: @escaping (URL?) -> Void) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original
        self.imageManager.requestAVAsset(forVideo: videoAsset, options: options, resultHandler: { (asset, audioMix, info) in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl = urlAsset.url
                completionHandler(localVideoUrl)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    private func loadImage(photoAsset: PHAsset, targetSize: CGSize) -> UIImage {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        var image = UIImage()
        self.imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: {(result, info)->Void in
            if let result = result {
                image = result
            }
        })
        return image
    }
    
    private func set(error: AuthorizationError?) {
        self.error = error
    }
    
    private func checkPermissions() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                print("Requested authorization with status \(newStatus)")
                if newStatus == .authorized {
                    self.loadPhotoData()
                } else {
                    self.set(error: .deniedAuthorization)
                }
            }
        case .authorized:
            self.loadPhotoData()
        case .restricted:
            self.set(error: .restrictedAuthorization)
        case .denied:
            self.set(error: .deniedAuthorization)
        default:
            self.set(error: .unknownAuthorization)
        }
    }
    
    private func loadPhotoData() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allPhotoAssets = PHAsset.fetchAssets(with: allPhotosOptions)
        allPhotos = PHFetchResultCollection(fetchResult: allPhotoAssets)
    }
}
