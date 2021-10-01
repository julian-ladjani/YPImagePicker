//
//  PostiOS10PhotoCapture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 08/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import CoreGraphics
import UIKit
import AVFoundation

@available(iOS 10.0, *)
class PostiOS10PhotoCapture: NSObject, YPPhotoCapture, AVCapturePhotoCaptureDelegate {

    let sessionQueue = DispatchQueue(label: "YPCameraVCSerialQueue", qos: .background)
    let session = AVCaptureSession()
    var deviceInput: AVCaptureDeviceInput?
    var device: AVCaptureDevice? { return deviceInput?.device }
    private let photoOutput = AVCapturePhotoOutput()
    var output: AVCaptureOutput { return photoOutput }
    var isCaptureSessionSetup: Bool = false
    var isPreviewSetup: Bool = false
    var previewView: UIView!
    var videoLayer: AVCaptureVideoPreviewLayer!
    var currentFlashMode: YPFlashMode = .off
    var hasFlash: Bool {
        guard let device = device else { return false }
        return device.hasFlash
    }
    var block: ((Data) -> Void)?
    var initVideoZoomFactor: CGFloat = 1.0
    
    // MARK: - Configuration
    
    private func newSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        settings.isAutoStillImageStabilizationEnabled = photoOutput.isStillImageStabilizationSupported

        // Set flash mode.
        if let deviceInput = deviceInput {
            if deviceInput.device.isFlashAvailable {
                switch currentFlashMode {
                case .auto:
                    if photoOutput.__supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.auto.rawValue)) {
                        settings.flashMode = .auto
                    }
                case .off:
                    if photoOutput.__supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.off.rawValue)) {
                        settings.flashMode = .off
                    }
                case .on:
                    if photoOutput.__supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.on.rawValue)) {
                        settings.flashMode = .on
                    }
                }
            }
        }
        return settings
    }
    
    func configure() {
        photoOutput.isHighResolutionCaptureEnabled = true
        
        // Improve capture time by preparing output with the desired settings.
        photoOutput.setPreparedPhotoSettingsArray([newSettings()], completionHandler: nil)
    }
    
    // MARK: - Flash
    
    func tryToggleFlash() {
        // if device.hasFlash device.isFlashAvailable //TODO test these
        switch currentFlashMode {
        case .auto:
            currentFlashMode = .on
        case .on:
            currentFlashMode = .off
        case .off:
            currentFlashMode = .auto
        }
    }
    
    // MARK: - Shoot

    func shoot(completion: @escaping (Data) -> Void) {
        block = completion
    
        // Set current device orientation
        setCurrentOrienation()
        
        let settings = newSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    var captureOutputPhotoRect: CGRect {
        return videoLayer.metadataOutputRectConverted(fromLayerRect: videoLayer.bounds)
    }

    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let rawData = photo.fileDataRepresentation(),
              let data = try? crop(photoData: rawData, toOutputRect: captureOutputPhotoRect)
        else { return }

        block?(data)
    }

    private func crop(photoData: Data, toOutputRect outputRect: CGRect) throws -> Data {
        guard let originalImage = UIImage(data: photoData) else {
            throw YPPhotoError("Fail generate image")
        }

        guard outputRect.width > 0, outputRect.height > 0 else {
            throw YPPhotoError("Image is 0 sized")
        }

        var cgImage = originalImage.cgImage!
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropRect = CGRect(x: outputRect.origin.x * width,
                              y: outputRect.origin.y * height,
                              width: outputRect.size.width * width,
                              height: outputRect.size.height * height)

        cgImage = cgImage.cropping(to: cropRect)!
        let croppedUIImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: originalImage.imageOrientation)
        guard let croppedData = croppedUIImage.heicData(compressionQuality: 0.8) ?? croppedUIImage.jpegData(compressionQuality: 0.8) else {
            throw YPPhotoError("cropped data is nil")
        }
        return croppedData
    }
}

extension UIImage {

    func heicData(compressionQuality: Float) -> Data? {
        let data = NSMutableData()
        guard let imageDestination =
                CGImageDestinationCreateWithData(
                    data, AVFileType.heic as CFString, 1, nil
                )
        else {
            return nil
        }

        guard let cgImage = self.cgImage else {
            return nil
        }

        let options: NSDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
            kCGImagePropertyOrientation: self.imageOrientation
        ]

        CGImageDestinationAddImage(imageDestination, cgImage, options)
        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }

        return data as Data
    }
}
