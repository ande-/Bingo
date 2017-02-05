//
//  TemplateTableViewCell.swift
//  Bingo
//
//  Created by Andrea Houg on 4/22/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class TemplateTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.textColor = kReddishBrownColor
        textLabel?.font = UIFont.systemFont(ofSize: 17)
        detailTextLabel?.textColor = kReddishBrownColor
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            textLabel?.textColor = UIColor.lightGray
        }
        else {
            self.textLabel?.textColor = kReddishBrownColor
        }
    }

}
