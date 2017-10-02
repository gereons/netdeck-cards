//
//  NRSwitch.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class NRSwitch: UISwitch {
    
    typealias Switcher = (Bool)->Void
    private var handler: Switcher?
    
    convenience init(initial: Bool, handler: @escaping Switcher) {
        self.init(frame: CGRect.zero)
        
        self.handler = handler
        self.isOn = initial
        self.addTarget(self, action: #selector(self.toggleSwitch(_:)), for: .valueChanged)
    }
    
    @objc func toggleSwitch(_ sender: UISwitch) {
        self.handler?(sender.isOn)
    }
}
