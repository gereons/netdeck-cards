//
//  Illuminotchi.swift
//  Illuminotchi
//
//  Created by Jeff Hurray on 12/20/17.
//  Copyright © 2018 Jeff Hurray. All rights reserved.
//
//  taken from https://github.com/jhurray/Illuminotchi
//

import Foundation
import UIKit
import DeviceKit

public protocol WindowProvider: class {
    var window: UIWindow? { get }
}

public final class Illuminotchi {

    private static let shared = Illuminotchi()
    private lazy var underlyingNotchView = UnderlyingNotchView()

    private var hasNotchView: Bool {
        DeviceKit.Device.current.hasSensorHousing
    }

    init() {
        let notificationCenter = NotificationCenter.default
        let keyWindowSelector = #selector(handle(windowDidBecomeKeyNotification:))
        notificationCenter.addObserver(self, selector: keyWindowSelector, name: UIWindow.didBecomeKeyNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public class func add(text: String) {
        self.add(attributedText: NSAttributedString(string: text))
    }

    public class func add(attributedText: NSAttributedString) {
        let label = UILabel()
        label.attributedText = attributedText
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        self.add(customView: label)
    }

    public class func add(customView view: UIView) {
        self.shared.addSubview(underNotch: view)
        self.shared.addToWindow()
    }

    @objc
    private func handle(windowDidBecomeKeyNotification notification: Notification) {
        guard hasNotchView else {
            return
        }
        self.addToWindow()
    }

    public func addToWindow() {
        if hasNotchView, let keyWindow = UIApplication.shared.keyWindow {
            self.underlyingNotchView.removeFromSuperview()
            keyWindow.addSubview(self.underlyingNotchView)
            keyWindow.bringSubviewToFront(self.underlyingNotchView)
        }
    }

    private func addSubview(underNotch view: UIView) {
        guard hasNotchView else {
            return
        }
        self.underlyingNotchView.addSubview(view)
    }

    private class UnderlyingNotchView: UIView {

        struct Constants {
            static let size = CGSize(width: 209, height: 30)
            static let origin = CGPoint(x: 83, y: 0)
        }

        weak var underlyingView: UIView?

        init() {
            let notchFrame = CGRect(origin: Constants.origin, size: Constants.size)
            super.init(frame: notchFrame)
            self.clipsToBounds = true
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func addSubview(_ view: UIView) {
            self.underlyingView?.removeFromSuperview()
            super.addSubview(view)
            self.underlyingView = view
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let view = self.underlyingView else {
                return
            }
            let size = CGSize(width: min(view.bounds.width, Constants.size.width),
                              height: min(view.bounds.height, Constants.size.height))
            view.frame = CGRect(x: self.bounds.width/2 - size.width/2,
                                y: self.bounds.height - size.height,
                                width: size.width,
                                height: size.height)
        }

    }
}
