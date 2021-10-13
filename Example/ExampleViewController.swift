//
//  ExampleViewController.swift
//  YPImagePickerExample
//
//  Created by Sacha DSO on 17/03/2017.
//  Copyright © 2017 Octopepper. All rights reserved.
//

import UIKit
import AVFoundation
import SDWebImage
import AVKit
import Photos

class ExampleViewController: UIViewController {
    var selectedItems = [YPMediaItem]()

    lazy var selectedImageV : UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: UIScreen.main.bounds.width,
                                                  height: UIScreen.main.bounds.height * 0.45))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var pickButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: 100,
                                            height: 100))
        button.setTitle("Pick", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
        return button
    }()

    lazy var resultsButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: UIScreen.main.bounds.height - 100,
                                            width: UIScreen.main.bounds.width,
                                            height: 100))
        button.setTitle("Show selected", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(showResults), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        view.addSubview(selectedImageV)
        view.addSubview(pickButton)
        pickButton.center = view.center
        view.addSubview(resultsButton)
    }

    @objc
    func showResults() {
        if !selectedItems.isEmpty {
            let gallery = YPSelectionsGalleryVC(items: selectedItems) { g, _ in
                g.dismiss(animated: true, completion: nil)
            }
            let navC = UINavigationController(rootViewController: gallery)
            self.present(navC, animated: true, completion: nil)
        } else {
            print("No items selected yet.")
        }
    }

    // MARK: - Configuration
    @objc
    func showPicker() {
        var config = YPImagePickerConfiguration()
        config.screens = [.library, .photo, .video]
        config.maxCameraZoomFactor = 10.0
        config.onlySquareImagesFromCamera = false
        config.albumName = "PandaLab Pro"
        config.showsCrop = .none
        config.showsPhotoFilters = false
        config.shouldSaveNewPicturesToAlbum = false

        config.library.mediaType = .photoAndVideo
        config.library.maxNumberOfItems = 10
        config.library.defaultMultipleSelection = false
        config.library.isSquareByDefault = false
        config.sizeLimit = 1000000
        config.video.recordingTimeLimit = .zero
        config.video.libraryTimeLimit = .zero
        config.video.minimumTimeLimit = .zero
        config.video.trimmerMinDuration = 0.1
        config.video.trimmerMaxDuration = .zero
        config.video.fileType = .mp4
        config.video.compression = AVAssetExportPresetMediumQuality

        config.photo.targetImageSize = .cappedTo(size: 1080)
        config.photo.targetImageCompression = 0.9
        config.showsCrop = .none

        let picker = YPImagePicker(configuration: config)

        picker.didFinishPicking { [weak picker] items, cancelled in

            if cancelled {
                print("Picker was canceled")
                picker?.dismiss(animated: true, completion: nil)
                return
            }
            _ = items.map { print("🧀 \($0)") }

            self.selectedItems = items
            if let firstItem = items.first {
                switch firstItem {
                case .photo(let photo):
                    self.selectedImageV.image = photo.image
                    picker?.dismiss(animated: true, completion: nil)
                    debugPrint(Float(photo.image.pngData()?.count ?? 0) / Float((1024*1024)))
                case .video(let video):
                    self.selectedImageV.image = video.thumbnail

                    let assetURL = video.url
                    let playerVC = AVPlayerViewController()
                    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
                    playerVC.player = player

                    picker?.dismiss(animated: true, completion: { [weak self] in
                        self?.present(playerVC, animated: true, completion: nil)
                        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
                    })
                case .animatedPhoto(let animatedPhoto):
                    self.selectedImageV.sd_setImage(with: animatedPhoto.url, completed: nil)
                    picker?.dismiss(animated: true, completion: nil)
                }
            }
        }

        /* Single Photo implementation. */
        // picker.didFinishPicking { [weak picker] items, _ in
        //     self.selectedItems = items
        //     self.selectedImageV.image = items.singlePhoto?.image
        //     picker.dismiss(animated: true, completion: nil)
        // }

        /* Single Video implementation. */
        // picker.didFinishPicking { [weak picker] items, cancelled in
        //    if cancelled { picker.dismiss(animated: true, completion: nil); return }
        //
        //    self.selectedItems = items
        //    self.selectedImageV.image = items.singleVideo?.thumbnail
        //
        //    let assetURL = items.singleVideo!.url
        //    let playerVC = AVPlayerViewController()
        //    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
        //    playerVC.player = player
        //
        //    picker.dismiss(animated: true, completion: { [weak self] in
        //        self?.present(playerVC, animated: true, completion: nil)
        //        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
        //    })
        //}

        present(picker, animated: true, completion: nil)
    }
}

// Support methods
extension ExampleViewController {
    /* Gives a resolution for the video by URL */
    func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}

// YPImagePickerDelegate
extension ExampleViewController: YPImagePickerDelegate {
    func imagePickerHasNoItemsInLibrary(_ picker: YPImagePicker) {
        // PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
    }

    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true // indexPath.row != 2
    }
}
