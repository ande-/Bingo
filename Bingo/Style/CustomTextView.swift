//
//  CustomTextView.swift
//  Bingo
//
//  Created by Andrea Houg on 4/22/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class CustomTextView: UITextView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textColor = kReddishBrownColor
        autocorrectionType = UITextAutocorrectionType.no
        if (isEditable) {
            backgroundColor = kBrownColor
        }
    }
}
