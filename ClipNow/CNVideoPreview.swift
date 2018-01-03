//
//  CVVideoPreview.swift
//  ClipNow
//
//  Created by ruckef on 29.06.16.
//  Copyright © 2016 ruckef. All rights reserved.
//

import UIKit
import GLKit

class CNVideoPreviewBlurred: UIView {
    
    var preview: UIView?
    var blurView: UIVisualEffectView?
    
    func addPreview(_ preview: UIView) {
        addSubview(preview)
        self.preview = preview
        
        let effect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: effect)
        addSubview(blurView!)
        blurView?.translatesAutoresizingMaskIntoConstraints = false
        blurView?.addSuperviewSizedConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        preview!.frame = bounds
        blurView!.frame = bounds
    }
}
