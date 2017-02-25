//
//  StartupViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.02.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class StartupViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private let backgroundColor = UIColor(rgb: 0xefeff4)
    private var dispatchGroup: DispatchGroup
    private var points = [CGPoint]()
    private var timeEstimate = 0.0
    private var interval = 0.0
    private let debugAnimation = true
    
    private let greys: [UIColor] = [
        UIColor(rgb: 0xefeff4),
        UIColor(rgb: 0xeeeef3),
        UIColor(rgb: 0xededf2),
        UIColor(rgb: 0xececf1),
//        UIColor(rgb: 0xe6e6eb),
//        UIColor(rgb: 0xdcdce0),
//        UIColor(rgb: 0xcdcdd1)
    ]
    
    required init(_ dispatchGroup: DispatchGroup, numberOfDecks: Int) {
        self.dispatchGroup = dispatchGroup
        self.dispatchGroup.enter()
        self.timeEstimate = 0.01 * Double(numberOfDecks) + 0.5
        print("\(self.timeEstimate)")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
        
        let size = UIScreen.main.bounds.size
        for row in 0 ... Int(Double(size.height) / Hex.rowHeight) {
            for col in 0 ... Int(Double(size.width) / Hex.columnWidth) {
                self.points.append(CGPoint(x: row, y: col))
            }
        }
        self.points.shuffle()
        self.interval = min(0.0015, self.timeEstimate / Double(self.points.count))
        print("\(interval)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if BuildConfig.debug && !self.debugAnimation {
            self.drawAllHexes()
        } else {
            self.drawHexSequence()
        }
    }
    
    func stopSpinner() {
        self.spinner.stopAnimating()
    }
    
    private func drawHexSequence() {
        print("draw hex sequence")
        DispatchQueue.main.async {
            self.drawNextHex()
        }
    }
    
    private func drawAllHexes() {
        self.points.forEach {
            self.addHexLayer(at: $0)
        }
        dispatchGroup.leave()
    }
    
    private func drawNextHex() {
        guard let point = self.points.popLast() else {
            self.view.bringSubview(toFront: spinner)
            self.spinner.startAnimating()
            self.dispatchGroup.leave()
            return
        }
        
        self.addHexLayer(at: point)
        DispatchQueue.main.asyncAfter(deadline: .now() + self.interval) {
            self.drawNextHex()
        }
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
        static let rowHeight = sin(M_PI / 3.0) * columnWidth
        
        static func path(at point: CGPoint) -> UIBezierPath {
            let row = Double(point.x)
            let col = Double(point.y)
            let evenOdd = Int(point.x) % 2
            var x = (col + 0.5 * Double(evenOdd)) * columnWidth
            var y = row * rowHeight
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y))
            for angle in stride(from: 0.0, to: 2.0 * M_PI, by: M_PI / 3.0) {
                x += sin(angle) * edgeLength
                y += cos(angle) * edgeLength
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.close()
            return path
        }
    }
}
