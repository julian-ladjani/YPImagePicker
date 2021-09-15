//
//  YPCameraViewDelegate.swift
//  YPImgePicker
//
//  Created by Julian Ladjani on 15/09/2021.
//

import Foundation

@objc
public protocol YPCameraViewDelegate: class {
    func cameraViewPermissionNotGranted()
}

