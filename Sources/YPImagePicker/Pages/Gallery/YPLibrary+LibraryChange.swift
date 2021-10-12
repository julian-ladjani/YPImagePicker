//
//  YPLibrary+LibraryChange.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            let fetchResult = self.mediaManager.fetchResult!
            let collectionChanges = changeInstance.changeDetails(for: fetchResult)
            if let collectionChanges = collectionChanges {
                self.mediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
                let collectionView = self.v.collectionView!
                if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                    collectionView.reloadData()
                } else {
                    collectionView.performBatchUpdates({
                        if let removedIndexes = collectionChanges.removedIndexes,
                           !removedIndexes.isEmpty {
                            collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        if let insertedIndexes = collectionChanges.insertedIndexes,
                           !insertedIndexes.isEmpty {
                            collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                        }
                    }, completion: { finished in
                        if finished {
                            if let changedIndexes = collectionChanges.changedIndexes,
                               !changedIndexes.isEmpty{
                                collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                            }
                        }
                    })
                }
                self.mediaManager.resetCachedAssets()
            }
        }
    }
}
