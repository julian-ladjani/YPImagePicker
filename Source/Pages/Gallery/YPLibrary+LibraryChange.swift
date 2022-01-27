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
        guard let fetchResult = self.mediaManager.fetchResult,
              let collectionChanges = changeInstance.changeDetails(for: fetchResult) else {
            ypLog("Some problems there.")
            return
        }

        DispatchQueue.main.async {
            let collectionView = self.v.collectionView
            self.mediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                collectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes,
                       removedIndexes.count != 0 {
                        collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes, insertedIndexes.count != 0 {
                        collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                }, completion: { finished in
                    guard finished,
                          let changedIndexes = collectionChanges.changedIndexes,
                          changedIndexes.count != 0 else {
                        ypLog("Some problems there.")
                        return
                    }

                    collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                })
            }

            self.updateAssetSelection(
                hasChangedIndexes: !(collectionChanges.changedIndexes?.isEmpty ?? true),
                hasInsertedIndexes: !(collectionChanges.insertedIndexes?.isEmpty ?? true),
                hasRemovedIndexes: !(collectionChanges.removedIndexes?.isEmpty ?? true)
            )
            self.mediaManager.resetCachedAssets()
        }
    }

    fileprivate func updateAssetSelection(hasChangedIndexes: Bool, hasInsertedIndexes: Bool, hasRemovedIndexes: Bool) {

        if !hasRemovedIndexes && !hasInsertedIndexes && !hasChangedIndexes {
            selectedItems.removeAll()
            currentlySelectedIndex = 0
            self.v.assetZoomableView.clearAsset()

            self.delegate?.libraryViewFinishedLoading()
            if let asset = mediaManager.fetchResult?.firstObject {
                self.changeAsset(asset)
            }
        } else {
            if self.mediaManager.hasResultItems,
               selectedItems.isEmpty,
               let newAsset = self.mediaManager.getAsset(at: 0) {
                self.changeAsset(newAsset)
            }

            if selectedItems.isEmpty == false,
               self.mediaManager.hasResultItems == false {
                self.v.assetZoomableView.clearAsset()
                self.selectedItems.removeAll()
                self.delegate?.libraryViewFinishedLoading()
            }
        }
    }
}
