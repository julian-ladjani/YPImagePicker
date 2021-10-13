//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public protocol YPImagePickerDelegate: AnyObject {
    func imagePickerHasNoItemsInLibrary(_ picker: YPImagePicker)
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
}

open class YPImagePicker: UINavigationController {
    public typealias DidFinishPickingCompletion = (_ items: [YPMediaItem], _ cancelled: Bool) -> Void

    // MARK: - Public

    public weak var imagePickerDelegate: YPImagePickerDelegate?
    public func didFinishPicking(completion: @escaping DidFinishPickingCompletion) {
        _didFinishPicking = completion
    }

    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        self.init(configuration: YPImagePickerConfiguration.shared)
    }

    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        YPImagePickerConfiguration.shared = configuration
        picker = YPPickerVC()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen // Force .fullScreen as iOS 13 now shows modals as cards by default.
        picker.pickerVCDelegate = self
        navigationBar.tintColor = .ypLabel
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return YPImagePickerConfiguration.shared.preferredStatusBarStyle
    }

    // MARK: - Private

    private var _didFinishPicking: DidFinishPickingCompletion?

    // This nifty little trick enables us to call the single version of the callbacks.
    // This keeps the backwards compatibility keeps the api as simple as possible.
    // Multiple selection becomes available as an opt-in.
    private func didSelect(items: [YPMediaItem]) {
        _didFinishPicking?(items, false)
    }
    
    private let loadingView = YPLoadingView()
    private let picker: YPPickerVC!

    override open func viewDidLoad() {
        super.viewDidLoad()
        picker.didClose = { [weak self] in
            self?._didFinishPicking?([], true)
        }
        viewControllers = [picker]
        setupLoadingView()
        navigationBar.isTranslucent = false

        picker.didSelectItems = { [weak self] items in
            // Use Fade transition instead of default push animation
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.fade
            self?.view.layer.add(transition, forKey: nil)
            
            // Multiple items flow
            if items.count > 1 {
                if YPConfig.library.skipSelectionsGallery {
                    if items.allSatisfy({ item in
                        self?.fitsSizeLimits(fileSize: item.size, showModal: false) ?? false
                    }) {
                        self?.didSelect(items: items)
                    } else {
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            let alert = YPAlert.severalSizeTooLongAlert(self.view)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    return
                } else {
                    let selectionsGalleryVC = YPSelectionsGalleryVC(items: items) { _, items in
                        if items.allSatisfy({ item in
                            self?.fitsSizeLimits(fileSize: item.size, showModal: false) ?? false
                        }) {
                            self?.didSelect(items: items)
                        }else {
                            DispatchQueue.main.async {
                                guard let self = self else { return }
                                let alert = YPAlert.severalSizeTooLongAlert(self.view)
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                    self?.pushViewController(selectionsGalleryVC, animated: true)
                    return
                }
            }
            
            // One item flow
            let item = items.first!
            switch item {
            case .photo(let photo):
                let completion = { (photo: YPMediaPhoto) in
                    let mediaItem = YPMediaItem.photo(p: photo)
                    // Save new image or existing but modified, to the photo album.
                    if YPConfig.shouldSaveNewPicturesToAlbum {
                        let isModified = photo.modifiedImage != nil
                        if photo.fromCamera || (!photo.fromCamera && isModified) {
                            YPPhotoSaver.trySaveImage(photo.image, inAlbumNamed: YPConfig.albumName)
                        }
                    }
                    if self?.fitsSizeLimits(fileSize: photo.size) ?? false {
                        self?.didSelect(items: [mediaItem])
                    }
                }
                
                func showCropVC(photo: YPMediaPhoto, completion: @escaping (_ aphoto: YPMediaPhoto) -> Void) {
                    switch YPConfig.showsCrop {
                    case .rectangle, .circle:
                        let cropVC = YPCropVC(image: photo.image)
                        cropVC.didFinishCropping = { croppedImage in
                            photo.modifiedImage = croppedImage
                            completion(photo)
                        }
                        self?.pushViewController(cropVC, animated: true)
                    default:
                        completion(photo)
                    }
                }
                
                if YPConfig.showsPhotoFilters {
                    let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                                                    isFromSelectionVC: false)
                    // Show filters and then crop
                    filterVC.didSave = { outputMedia in
                        if case let YPMediaItem.photo(outputPhoto) = outputMedia {
                            showCropVC(photo: outputPhoto, completion: completion)
                        }
                    }
                    self?.pushViewController(filterVC, animated: false)
                } else {
                    showCropVC(photo: photo, completion: completion)
                }
            case .animatedPhoto(let animatedPhoto):
                let completion = { (animatedPhoto: YPMediaAnimatedPhoto) in
                    let mediaItem = YPMediaItem.animatedPhoto(a: animatedPhoto)
                    // Save new image or existing but modified, to the photo album.
                    if YPConfig.shouldSaveNewPicturesToAlbum {
                        if animatedPhoto.fromCamera {
                            YPPhotoSaver.trySaveAnimatedImage(animatedPhoto.url, inAlbumNamed: YPConfig.albumName)
                        }
                    }
                    if (self?.fitsSizeLimits(fileSize: animatedPhoto.size) ?? false) {
                        self?.didSelect(items: [mediaItem])
                    }
                }
                completion(animatedPhoto)
            case .video(let video):
                if YPConfig.showsVideoTrimmer {
                    let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                                                                   isFromSelectionVC: false)
                    videoFiltersVC.didSave = { [weak self] outputMedia in
                        if self?.fitsSizeLimits(fileSize: outputMedia.size) ?? false {
                            self?.didSelect(items: [outputMedia])
                        }
                    }
                    self?.pushViewController(videoFiltersVC, animated: true)
                } else {
                    self?.didSelect(items: [YPMediaItem.video(v: video)])
                }
            }
        }
    }
    
    deinit {
        ypLog("Picker deinited 👍")
    }
    
    private func setupLoadingView() {
        view.subviews(
            loadingView
        )
        loadingView.fillContainer()
        loadingView.alpha = 0
    }
}

extension YPImagePicker: YPPickerVCDelegate {
    func libraryHasNoItems() {
        self.imagePickerDelegate?.imagePickerHasNoItemsInLibrary(self)
    }
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return self.imagePickerDelegate?.shouldAddToSelection(indexPath: indexPath, numSelections: numSelections)
            ?? true
    }
}

extension UIViewController {
    func fitsSizeLimits(fileSize: Int64, showModal: Bool = true) -> Bool {
        let tooLong: Bool
        if let librarySizeLimit = YPConfig.sizeLimit {
            tooLong = fileSize > librarySizeLimit
        } else {
            tooLong = false
        }

        if tooLong {
            if showModal {
                DispatchQueue.main.async {
                    let alert = YPAlert.sizeTooLongAlert(self.view)
                    self.present(alert, animated: true, completion: nil)
                }
            }
            return false
        }

        return true
    }
}

extension URL {
    func getSize() -> Int64 {
        let size: Int = (try? self.resourceValues(forKeys:[.fileSizeKey]).fileSize) ?? .zero
        return Int64(size)
    }
}

extension PHAsset {
    func getSize() -> Int64 {
        let resource = PHAssetResource.assetResources(for: self)
        return (resource.first?.value(forKey: "fileSize") as? Int64) ?? .zero
    }
}

extension Data {
    func getSize() -> Int64 {
        return Int64(self.count)
    }
}

extension UIImage {
    func getSize() -> Int64 {
        return (self.pngData() ?? self.jpegData(compressionQuality: 1.0))?.getSize() ?? .zero
    }
}

extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return String(formatter.string(from: number) ?? "")
    }
}
