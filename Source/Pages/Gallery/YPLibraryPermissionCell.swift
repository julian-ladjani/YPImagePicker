//
//  YPLibraryPermissionCell.swift
//  YPImagePicker
//
//  Created by Julian Ladjani on 25/01/2022.
//  Copyright © 2022 Yummypets. All rights reserved.
//

import UIKit
import Stevia


protocol YPLibraryPermissionCellDelegate: AnyObject {
    func permissionManageButtonTouch()
}

class YPLibraryPermissionCell: UICollectionViewCell {
    weak var delegate: YPLibraryPermissionCellDelegate?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = YPConfig.fonts.limitedLibraryPermissionTitleFont
        label.text = String(format: YPConfig.wordings.libraryPermissionCell.title, Bundle.main.displayName ?? "")
        label.textColor = YPConfig.colors.limitedLibraryPermissionLabelColor
        return label
    }()

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(YPConfig.wordings.libraryPermissionCell.button, for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitleColor(YPConfig.colors.limitedLibraryPermissionButtonColor, for: .normal)
        button.titleLabel?.font = YPConfig.fonts.limitedLibraryPermissionButtonFont
        button.addTarget(self, action: #selector(manageButtonTouched), for: .touchUpInside)
        return button
    }()

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override init(frame: CGRect) {
        super.init(frame: frame)

        sv(
            titleLabel,
            button
        )

        layout(
            0,
            |-titleLabel-8-button-|,
            0
        )

        backgroundColor = .ypSecondarySystemBackground
        setAccessibilityInfo()
    }

    private func setAccessibilityInfo() {
        isAccessibilityElement = true
        self.accessibilityIdentifier = "YPLibraryPermissionCell"
        self.accessibilityLabel = "Library Permission"
    }

    @objc
    private func manageButtonTouched() {
        delegate?.permissionManageButtonTouch()
    }
}

private extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}
