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
    private var handler: Switcher
    
    required init(initial: Bool, handler: @escaping Switcher) {
        self.handler = handler
        super.init(frame: CGRect.zero)

        self.isOn = initial
        self.addTarget(self, action: #selector(self.toggleSwitch(_:)), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func toggleSwitch(_ sender: UISwitch) {
        self.handler(sender.isOn)
    }
}
