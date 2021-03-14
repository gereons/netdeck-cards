//
//  StartupViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.02.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class StartupViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var backgroundColor: UIColor {
        if #available(iOS 13, *), UITraitCollection.current.userInterfaceStyle == .dark {
            return UIColor(rgb: 0xffffff - 0xefeff4)
        }
        return UIColor(rgb: 0xefeff4)
    }

    private var strokeColor: UIColor {
        if #available(iOS 13, *), UITraitCollection.current.userInterfaceStyle == .dark {
            return .systemGray
        }
        return .white
    }

    private let greyValues: [UInt] = [
        0xefeff4, 0xeeeef3, 0xededf2, 0xececf1, 0xebebf0, 0xeaeaef, 0xe9e9ee
    ]

    private var greys: [UIColor] {
        if #available(iOS 13, *), UITraitCollection.current.userInterfaceStyle == .dark {
            return greyValues.map { UIColor(rgb: (0xffffff - $0) * 2) }
        }
        return greyValues.map { UIColor(rgb: $0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let size = UIScreen.main.bounds.size
        for row in 0 ... Int(Double(size.height) / Hex.rowHeight) {
            for col in -1 ... Int(Double(size.width) / Hex.columnWidth) {
                self.addHexLayer(at: CGPoint(x: row, y: col))
            }
        }
        
        self.view.bringSubviewToFront(spinner)
        self.spinner.startAnimating()
    }
        
    func stopSpinner() {
        self.spinner.stopAnimating()
    }
    
    private func addHexLayer(at point: CGPoint) {
        let layer = CAShapeLayer()
        layer.path = Hex.path(at: point).cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 4.0
        let color = self.greys.randomElement() ?? .lightGray
        layer.fillColor = color.cgColor
        
        self.view.layer.addSublayer(layer)
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
