//
//  SmallPipsView.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.10.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class SmallPipsView: UIView {
    @IBOutlet weak var pipNW: UIView!
    @IBOutlet weak var pipNE: UIView!
    @IBOutlet weak var pipSW: UIView!
    @IBOutlet weak var pipSE: UIView!
    @IBOutlet weak var pipCenter: UIView!
    
    private var views = [UIView]()
    
    static func create() -> SmallPipsView {
        let view = Bundle.main.loadNibNamed("SmallPipsView", owner: self, options:nil)?.first
        let pips = view as! SmallPipsView
        pips.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        return pips
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.views = [ self.pipNW, self.pipNE, self.pipCenter, self.pipSW, self.pipSE ]
        for view in self.views {
            view.layer.cornerRadius = 2
        }
        self.hideAll()
    }
    
    func set(value: Int, color: UIColor) {
        self.views.forEach { $0.backgroundColor = color }
        self.set(value: value)
    }
    
    private func set(value: Int) {
        let show: [UIView]
        switch value {
        case 1: show = [ self.pipCenter ]
        case 2: show = [ self.pipNE, self.pipSW ]
        case 3: show = [ self.pipNW, self.pipSE, self.pipCenter ]
        case 4: show = [ self.pipNW, self.pipSE, self.pipSW, self.pipNE ]
        case 5: show = self.views
        default: show = []
        }
        self.hideAll()
        show.forEach { $0.isHidden = false }
    }

    private func hideAll() {
        self.views.forEach { $0.isHidden = true }
    }
    
}
