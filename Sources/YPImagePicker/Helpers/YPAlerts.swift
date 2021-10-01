//
//  YPAlert.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlert {
    static func videoTooLongAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooLongMessage,
                         "\(YPConfig.video.libraryTimeLimit ?? 60.0)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
												  y: sourceView.bounds.midY,
												  width: 0,
												  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooShortMessage,
                         "\(YPConfig.video.minimumTimeLimit)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
												  y: sourceView.bounds.midY,
												  width: 0,
												  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }

    static func sizeTooLongAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.librarySizePopup.tooLongMessage,
                         "\((Double(YPConfig.library.sizeLimit ?? 0) / (1024.0 * 1024.0)).removeZerosFromEnd())")
        let alert = UIAlertController(title: YPConfig.wordings.librarySizePopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
                                                  y: sourceView.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }

    static func severalSizeTooLongAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: YPConfig.wordings.librarySeveralSizePopup.tooLongMessage,
                         "\((Double(YPConfig.library.sizeLimit ?? 0) / (1024.0 * 1024.0)).removeZerosFromEnd())")
        let alert = UIAlertController(title: YPConfig.wordings.librarySeveralSizePopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
                                                  y: sourceView.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
}
