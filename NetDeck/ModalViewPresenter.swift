//
//  ModalViewController.swift
//  Net Deck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

//
//  Based on http://stackoverflow.com/questions/26994655/modal-transition-style-like-in-mail-app
//

///
/// present a UIViewController modally, "on top" of its parent, like the compose view in Mail.app
///
/// these view controllers must have a property of type `ModalViewController` so that they can call `dismiss()`
///
/// usage:
///
///     let controller = MyViewController()
///     let modalPresenter = ModalViewPresenter(withViewController: controller)
///     controller.presenter = modalPresenter
///     modalPresenter.present(on: self)
///

import UIKit

class ModalViewPresenter: UIViewController {

    /// distance from top of the screen
    private let topOffset: CGFloat = 25
    
    /// factor by which the presenting VC is scaled down
    private let transitionScale = CGAffineTransform.init(scaleX: 0.9, y: 0.95)
    
    /// alpha for dimming the presenting VC
    private let transitionAlpha: CGFloat = 0.9
    
    /// duration of the shrink/grow animation
    private let transitionDuration: TimeInterval = 0.2

    private let navController: UINavigationController
    private var presenter: UIViewController!

    required init(with viewController: UIViewController) {
        self.navController = UINavigationController(rootViewController: viewController)
        super.init(nibName: nil, bundle: nil)
        
        self.view.backgroundColor = .clear
        self.view.addSubview(self.navController.view)

        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds = self.view.bounds
        self.navController.view.frame = CGRect(x: 0, y: self.topOffset, width: bounds.width, height: bounds.height - self.topOffset)
    }

    func present(on viewController: UIViewController) {
        self.presenter = viewController
        viewController.navigationController?.view.layer.shouldRasterize = true
        viewController.navigationController?.view.layer.rasterizationScale = UIScreen.main.scale

        UIView.animate(withDuration: transitionDuration) {
            viewController.navigationController?.view.transform = self.transitionScale
            viewController.navigationController?.view.alpha = self.transitionAlpha
            viewController.present(self, animated: true, completion: nil)
            viewController.navigationController?.view.layer.shouldRasterize = false
            viewController.navigationController?.navigationBar.barStyle = .black
        }
    }

    func dismiss() {
        UIView.animate(withDuration: transitionDuration) {
            self.presenter.navigationController?.view.alpha = 1
            self.presenter.navigationController?.view.transform = CGAffineTransform.identity
            self.presenter.dismiss(animated: true, completion: nil)
            self.presenter.navigationController?.navigationBar.barStyle = .default
        }
    }
}
