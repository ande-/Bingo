//
//  CustomButton.swift
//  Bingo
//
//  Created by Andrea Houg on 4/22/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = frame.size.height/2
        layer.borderColor = kBrownColor.cgColor
        layer.borderWidth = 1.0
        self .setTitleColor(kReddishBrownColor, for: UIControlState())
        self.setTitleColor(kBrownColor, for: UIControlState.disabled)
    }
}
