//
//  PermissionCheckable.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 25/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit

internal protocol YPPermissionCheckable {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void, invalidBlock: (() -> Void)?)
    func doAfterCameraPermissionCheck(block: @escaping () -> Void, invalidBlock: (() -> Void)?)
    func checkLibraryPermission()
    func checkCameraPermission()
}

internal extension YPPermissionCheckable where Self: UIViewController {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void, invalidBlock: (() -> Void)? = nil) {
        YPPermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                invalidBlock?()
                ypLog("Not enough permissions.")
            }
        }
    }

    func doAfterCameraPermissionCheck(block: @escaping () -> Void, invalidBlock: (() -> Void)? = nil) {
        YPPermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                invalidBlock?()
                ypLog("Not enough permissions.")
            }
        }
    }

    func checkLibraryPermission() {
        YPPermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
    
    func checkCameraPermission() {
        YPPermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
}
