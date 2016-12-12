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


extension UILabel
{
    func adjustFont()
    {
        
        let testLabel = UILabel();
        let words:[String] = (self.text?.components(separatedBy: " "))!
        var longest = ""
        for word in words {
            if (word.characters.count > longest.characters.count) {
                longest = word
            }
        }
        
        testLabel.text = longest
        testLabel.numberOfLines = 1
        testLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        var maxSize: CGFloat = 12.0
        let minSize: CGFloat = 5.0
        testLabel.font = UIFont.systemFont(ofSize: maxSize)
        testLabel.sizeToFit()
        
        while(testLabel.frame.size.width > self.frame.size.width && maxSize > minSize)
        {
            maxSize = maxSize - 1
            testLabel.font = UIFont.systemFont(ofSize: maxSize)
            testLabel.sizeToFit()
        }
        self.font = UIFont.systemFont(ofSize: maxSize)
        
        
        
    }
}
