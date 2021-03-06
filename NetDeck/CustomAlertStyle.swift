//
//  CustomAlertStyle.swift
//  NetDeck
//
//  Created by Gereon Steffens on 02.04.18.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import SDCAlertView

class CustomAlertVisualStyle: AlertVisualStyle {
    override init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: alertStyle)
        self.backgroundColor = .white
    }
}
