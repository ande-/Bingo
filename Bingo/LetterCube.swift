//
//  LetterCube.swift
//  Bingo
//
//  Created by Andrea Houg on 2/2/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class LetterCube: UICollectionViewCell {
    
@IBOutlet weak var titleLabel: UILabel!
    var index:CGPoint = CGPoint(x: 0, y: 0)

    var markedView:MarkedView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = kTanColor

    }
    override func layoutSubviews() {
        super.layoutSubviews()
        markedView?.frame = contentView.frame
    }
    
    func mark(_ marked:Bool) {
        if markedView == nil {
            markedView = MarkedView(frame: contentView.frame)
        }
        if marked {
            contentView.addSubview(markedView!)
        }
        else {
            markedView?.removeFromSuperview()
        }
    }
}
