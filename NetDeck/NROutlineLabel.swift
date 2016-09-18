//
//  NROutlineLabel.swift
//  NetDeck
//
//  Created by Gereon Steffens on 24.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class NROutlineLabel: UILabel {
    fileprivate let outlineWidth: CGFloat = 2.0
    fileprivate let outlineColor = UIColor.white
    
    override func drawText(in rect: CGRect) {
        let textColor = self.textColor
        let shadowOffset = self.shadowOffset
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setLineWidth(self.outlineWidth)
        ctx?.setLineJoin(.round)
        ctx?.setTextDrawingMode(.stroke)
        self.textColor = self.outlineColor
        super.drawText(in: rect)
        
        ctx?.setTextDrawingMode(.fill)
        self.textColor = textColor
        self.shadowOffset = CGSize.zero
        super.drawText(in: rect)
        
        self.shadowOffset = shadowOffset
    }
}
