//
//  NROutlineLabel.swift
//  NetDeck
//
//  Created by Gereon Steffens on 24.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class NROutlineLabel: UILabel {
    private let outlineWidth: CGFloat = 2.0
    private let outlineColor = UIColor.whiteColor()
    
    override func drawTextInRect(rect: CGRect) {
        let textColor = self.textColor
        let shadowOffset = self.shadowOffset
        
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(ctx, self.outlineWidth)
        CGContextSetLineJoin(ctx, .Round)
        CGContextSetTextDrawingMode(ctx, .Stroke)
        self.textColor = self.outlineColor
        super.drawTextInRect(rect)
        
        CGContextSetTextDrawingMode(ctx, .Fill)
        self.textColor = textColor
        self.shadowOffset = CGSize.zero
        super.drawTextInRect(rect)
        
        self.shadowOffset = shadowOffset
    }
}
