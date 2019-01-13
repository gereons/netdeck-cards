//
//  TickingLabel.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.04.17.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class TickingLabel: UILabel {
    
    private var timer: Timer?
    private var currentIndex = 0
    
    var strings: [String]? {
        didSet {
            stop()
            self.currentIndex = 0
            let count = strings?.count ?? 0
            if count > 1 {
                self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.timerTick(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc private func timerTick(_ timer: Timer) {
        guard let strings = self.strings else {
            return self.stop()
        }
        
        self.currentIndex += 1
        if self.currentIndex >= strings.count {
            self.currentIndex = 0
        }
        
        let animation = CATransition()
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        self.layer.add(animation, forKey: CATransitionType.fade.rawValue)
        
        self.text = strings[self.currentIndex]
    }
}
