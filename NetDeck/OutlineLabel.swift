//
//  OutlineLabel.swift
//  NetDeck
//
//  Created by Gereon Steffens on 24.04.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

@IBDesignable
class OutlineLabel: UILabel {
    private let outlineWidth: CGFloat = 2.0
    private let outlineColor = UIColor.white
    
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
