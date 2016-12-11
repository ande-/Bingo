//
//  CustomTextField.swift
//  Bingo
//
//  Created by Andrea Houg on 4/22/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = kBrownColor
        textColor = kReddishBrownColor
        autocorrectionType = UITextAutocorrectionType.no
    }

}
