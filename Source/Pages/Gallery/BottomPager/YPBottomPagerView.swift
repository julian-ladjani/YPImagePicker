//
//  YPBottomPagerView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPBottomPagerView: UIView {
    
    var header = YPPagerMenu()
    var scrollView = UIScrollView()
    var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .offWhiteOrBlack
        return view
    }()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .offWhiteOrBlack
        
        subviews(
            scrollView,
            header,
            bottomView
        )
        
        layout(
            0,
            |scrollView|,
            0,
            |header| ~ 44,
            0,
            |bottomView|
        )
        
        if #available(iOS 11.0, *) {
            bottomView.Top == safeAreaLayoutGuide.Bottom
        } else {
            bottomView.Top == 0
        }
        bottomView.Bottom == 0
        bottomView.heightConstraint?.constant = (YPConfig.hidesBottomBar || (YPConfig.screens.count == 1)) ? 0 : self.safeAreaInsets.bottom
        header.heightConstraint?.constant = (YPConfig.hidesBottomBar || (YPConfig.screens.count == 1)) ? 0 : 44
        
        clipsToBounds = false
        setupScrollView()
    }

    private func setupScrollView() {
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
    }
}
