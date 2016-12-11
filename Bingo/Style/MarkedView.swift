//
//  MarkedView.swift
//  Bingo
//
//  Created by Andrea Houg on 5/15/16.
//  Copyright © 2016 a. All rights reserved.
//

import UIKit

class MarkedView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func draw(_ rect: CGRect)
    {
        let criss = UIBezierPath()
        criss.move(to: rect.origin)
        criss.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        
        criss.move(to: CGPoint(x: rect.size.width, y: 0))
        criss.addLine(to: CGPoint(x: 0, y: rect.size.height))
        criss.lineWidth = 3
        kReddishBrownColor.setStroke()
        criss.stroke()
        let cross = UIBezierPath()
        cross.move(to: CGPoint(x: rect.size.width, y: 0))
        cross.addLine(to: CGPoint(x: 0, y: rect.size.height))
        
    }
    

}
