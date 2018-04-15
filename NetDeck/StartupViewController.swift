//
//  StartupViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.02.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

class StartupViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private let backgroundColor = UIColor(rgb: 0xefeff4)
    
    private let greys: [UIColor] = [
        UIColor(rgb: 0xefeff4),
        UIColor(rgb: 0xeeeef3),
        UIColor(rgb: 0xededf2),
        UIColor(rgb: 0xececf1),
        UIColor(rgb: 0xebebf0),
        UIColor(rgb: 0xeaeaef),
        UIColor(rgb: 0xe9e9ee)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let size = UIScreen.main.bounds.size
        for row in 0 ... Int(Double(size.height) / Hex.rowHeight) {
            for col in 0 ... Int(Double(size.width) / Hex.columnWidth) {
                self.addHexLayer(at: CGPoint(x: row, y: col))
            }
        }
        
        self.view.bringSubview(toFront: spinner)
        self.spinner.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if BuildConfig.debug {
            let overlayClass = NSClassFromString("UIDebuggingInformationOverlay") as? UIWindow.Type
            _ = overlayClass?.perform(NSSelectorFromString("prepareDebuggingOverlay"))
//            let overlay = overlayClass?.perform(NSSelectorFromString("overlay")).takeUnretainedValue() as? UIWindow
//            _ = overlay?.perform(NSSelectorFromString("toggleVisibility"))
        }

    }
    
    func stopSpinner() {
        self.spinner.stopAnimating()
    }
    
    private func addHexLayer(at point: CGPoint) {
        let layer = CAShapeLayer()
        layer.path = Hex.path(at: point).cgPath
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 4.0
        layer.fillColor = self.randomGrey().cgColor
        
        self.view.layer.addSublayer(layer)
    }
    
    private func randomGrey() -> UIColor {
        let r = Int(arc4random_uniform(UInt32(self.greys.count)))
        return self.greys[r]
    }
    
    private struct Hex {
        static let edgeLength = 33.0
        static let columnWidth = edgeLength * sqrt(3)
        static let rowHeight = sin(.pi / 3.0) * columnWidth
        
        static func path(at point: CGPoint) -> UIBezierPath {
            let row = Double(point.x)
            let col = Double(point.y)
            let evenOdd = Int(point.x) % 2
            var x = (col + 0.5 * Double(evenOdd)) * columnWidth
            var y = row * rowHeight
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y))
            for angle in stride(from: 0.0, to: 2.0 * .pi, by: .pi / 3.0) {
                x += sin(angle) * edgeLength
                y += cos(angle) * edgeLength
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.close()
            return path
        }
    }
}
