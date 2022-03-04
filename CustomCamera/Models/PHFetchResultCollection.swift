//
//  PHFetchResultCollection.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/3/22.
//

import Photos

struct PHFetchResultCollection: RandomAccessCollection, Equatable {
    typealias Element = PHAsset
    typealias Index = Int
    
    let fetchResult: PHFetchResult<PHAsset>

    var startIndex: Int { 0 }
    var endIndex: Int { fetchResult.count }
    
    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: fetchResult.count - position - 1)
    }
}
