//
//  YPLibraryVC+CollectionView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC {
    var isLimitExceeded: Bool { return selectedItems.count >= YPConfig.library.maxNumberOfItems }
    
    func setupCollectionView() {
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        v.collectionView.register(YPLibraryViewCell.self, forCellWithReuseIdentifier: "YPLibraryViewCell")
        v.collectionView.register(YPLibraryPermissionCell.self, forCellWithReuseIdentifier: "YPLibraryPermissionCell")
        
        // Long press on cell to enable multiple selection
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        v.collectionView.addGestureRecognizer(longPressGR)
    }
    
    /// When tapping on the cell with long press, clear all previously selected cells.
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if isMultipleSelectionEnabled || isProcessing || YPConfig.library.maxNumberOfItems <= 1 {
            return
        }
        
        if longPressGR.state == .began {
            let point = longPressGR.location(in: v.collectionView)
            guard let indexPath = v.collectionView.indexPathForItem(at: point) else {
                return
            }
            startMultipleSelection(at: indexPath)
        }
    }
    
    func startMultipleSelection(at indexPath: IndexPath) {
        currentlySelectedIndex = indexPath.row
        toggleMultipleSelection()
        
        // Update preview.
        changeAsset(mediaManager.getAsset(at: indexPath.row))

        // Bring preview down and keep selected cell visible.
        panGestureHelper.resetToOriginalState()
        if !panGestureHelper.isImageShown {
            v.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
    }
    
    // MARK: - Library collection view cell managing
    
    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        guard v.collectionView.cellForItem(at: indexPath) is YPLibraryViewCell else { return }
        if let positionIndex = selectedItems.firstIndex(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		}) {
            selectedItems.remove(at: positionIndex)

            // Refresh the numbers
            let selectedIndexPaths = selectedItems.map { IndexPath(row: $0.index, section: 0) }
            v.collectionView.reloadItems(at: selectedIndexPaths)
			
            // Replace the current selected image with the previously selected one
            if let previouslySelectedIndexPath = selectedIndexPaths.last {
                v.collectionView.deselectItem(at: indexPath, animated: false)
                v.collectionView.selectItem(at: previouslySelectedIndexPath, animated: false, scrollPosition: [])
                currentlySelectedIndex = previouslySelectedIndexPath.row
                changeAsset(mediaManager.getAsset(at: previouslySelectedIndexPath.row))
            }
			
            checkLimit()
        }
    }
    
    /// Adds cell to selection
    func addToSelection(indexPath: IndexPath) {
        guard v.collectionView.cellForItem(at: indexPath) is YPLibraryViewCell else { return }
        if !(delegate?.libraryViewShouldAddToSelection(indexPath: indexPath,
                                                       numSelections: selectedItems.count) ?? true) {
            return
        }
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            print("No asset to add to selection.")
            return
        }

        let newSelection = YPLibrarySelection(index: indexPath.row, assetIdentifier: asset.localIdentifier)
        selectedItems.append(newSelection)
        checkLimit()
    }
    
    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selectedItems.contains(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
		})
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        v.maxNumberWarningView.isHidden = !isLimitExceeded || isMultipleSelectionEnabled == false
    }
}

extension YPLibraryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.cellCount()
    }
}

extension YPLibraryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 14, *),
           indexPath.item == .zero,
           PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryPermissionCell", for: indexPath) as? YPLibraryPermissionCell else {
                fatalError("unexpected cell in collection view")
            }
            cell.delegate = self
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YPLibraryViewCell", for: indexPath) as? YPLibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            return cell
        }

        cell.representedAssetIdentifier = asset.localIdentifier
        cell.multipleSelectionIndicator.selectionColor =
            YPConfig.colors.multipleItemsSelectedCircleColor ?? YPConfig.colors.tintColor
        mediaManager.imageManager?.requestImage(for: asset,
                                   targetSize: v.cellSize(),
                                   contentMode: .aspectFill,
                                   options: nil) { image, _ in
                                    // The cell may have been recycled when the time this gets called
                                    // set image only if it's still showing the same asset.
                                    if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                                        cell.imageView.image = image
                                    }
        }
        
        let isVideo = (asset.mediaType == .video)
        cell.durationLabel.isHidden = !isVideo
        cell.durationLabel.text = isVideo ? YPHelper.formattedStrigFrom(asset.duration) : ""
        cell.multipleSelectionIndicator.isHidden = !isMultipleSelectionEnabled
        cell.isSelected = currentlySelectedIndex == indexPath.row
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == asset.localIdentifier }) {
            let currentSelection = selectedItems[index]
            if currentSelection.index < 0 {
                selectedItems[index] = YPLibrarySelection(index: indexPath.row,
                                                      cropRect: currentSelection.cropRect,
                                                      scrollViewContentOffset: currentSelection.scrollViewContentOffset,
                                                      scrollViewZoomScale: currentSelection.scrollViewZoomScale,
                                                      assetIdentifier: currentSelection.assetIdentifier)
            }
            cell.multipleSelectionIndicator.set(number: index + 1) // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.set(number: nil)
        }

        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard v.collectionView.cellForItem(at: indexPath) is YPLibraryViewCell else { return }
        let previouslySelectedIndexPath = IndexPath(row: currentlySelectedIndex, section: 0)
        currentlySelectedIndex = indexPath.row

        changeAsset(mediaManager.getAsset(at: indexPath.row))
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelectedIndexPath.row == currentlySelectedIndex
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                }
            } else if isLimitExceeded == false {
                addToSelection(indexPath: indexPath)
            }
            collectionView.reloadItems(at: [indexPath])
            collectionView.reloadItems(at: [previouslySelectedIndexPath])
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: indexPath)
            
            // Force deseletion of previously selected cell.
            // In the case where the previous cell was loaded from iCloud, a new image was fetched
            // which triggered photoLibraryDidChange() and reloadItems() which breaks selection.
            //
            if let previousCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as? YPLibraryViewCell {
                previousCell.isSelected = false
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard v.collectionView.cellForItem(at: indexPath) is YPLibraryViewCell else { return false }
        return isProcessing == false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard v.collectionView.cellForItem(at: indexPath) is YPLibraryViewCell else { return false }
        return isProcessing == false
    }
}

extension YPLibraryVC: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        if #available(iOS 14, *),
           indexPath.item == .zero,
           PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            return CGSize(width: UIScreen.main.bounds.width, height: 60.0)
        }
        let margins = YPConfig.library.spacingBetweenItems * CGFloat(YPConfig.library.numberOfItemsInRow - 1)
        let width = (collectionView.frame.width - margins) / CGFloat(YPConfig.library.numberOfItemsInRow)
        return CGSize(width: width, height: width)
    }

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }

    public func collectionView(_ collectionView: UICollectionView,
							   layout collectionViewLayout: UICollectionViewLayout,
							   minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return YPConfig.library.spacingBetweenItems
    }
}

extension YPLibraryVC: YPLibraryPermissionCellDelegate {
    func permissionManageButtonTouch() {
        let actionSheet = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        let selectPhotosAction = UIAlertAction(
            title: YPConfig.wordings.libraryPermissionCell.selectMore,
            style: .default
        ) { [weak self] (_) in
            if #available(iOS 14, *), let self = self {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }
        }

        actionSheet.addAction(selectPhotosAction)

        let allowFullAccessAction = UIAlertAction(
            title: YPConfig.wordings.libraryPermissionCell.editPermissions,
            style: .default
        ) { [weak self] (_) in
            // Open app privacy settings
            self?.gotoAppPrivacySettings()
        }
        actionSheet.addAction(allowFullAccessAction)

        let cancelAction = UIAlertAction(title: YPConfig.wordings.cancel, style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func gotoAppPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
                  assertionFailure("Not able to open App privacy settings")
                  return
              }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
