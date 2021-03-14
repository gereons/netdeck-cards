//
//  ModalCardImageViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.04.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class ModalCardImageViewController: UIViewController, CardDetailDisplay {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardType: UILabel!
    @IBOutlet weak var cardText: UITextView!

    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var icon1: UIImageView!
    @IBOutlet weak var icon2: UIImageView!
    @IBOutlet weak var icon3: UIImageView!
    
    weak var modalPresenter: ModalViewPresenter?
    private let card: Card
    private var showText: Bool
    private var tapGesture: UITapGestureRecognizer!

    init(card: Card, showText: Bool = true) {
        self.card = card
        self.showText = showText

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done".localized(), style: .plain, target: self, action: #selector(self.dismiss(_:)))

        self.imageView.layer.cornerRadius = 10
        self.imageView.clipsToBounds = true
        self.imageView.isUserInteractionEnabled = true

        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.toggleDisplay(_:)))
        self.imageView.addGestureRecognizer(self.tapGesture)

        if #available(iOS 14, *), self.modalPresentationStyle == .pageSheet {
            let closeBtn = UIButton(type: .close, primaryAction: UIAction { _ in
                self.dismiss(animated: true)
            })
            closeBtn.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(closeBtn)
            NSLayoutConstraint.activate([
                closeBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 16),
                closeBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16)
            ])
        }

        self.configure()
    }

    private func configure() {
        self.detailView.isHidden = !showText
        if showText {
            self.activityIndicator.stopAnimating()
            self.imageView.image = ImageCache.placeholder(for: card.role)
            CardDetailView.setup(from: self, card: card)
        } else {
            self.loadImage(for: card)
        }
    }

    @objc func dismiss(_ button: UIBarButtonItem) {
        modalPresenter?.dismiss()
    }

    @objc private func toggleDisplay(_ gesture: UIGestureRecognizer) {
        self.showText.toggle()
        self.configure()
    }
    
    func loadImage(for card: Card) {
        ImageCache.sharedInstance.getImage(for: card) { card, image, placeholder in
            self.activityIndicator.stopAnimating()
            self.imageView.image = image

            if placeholder {
                self.showText = true
                self.imageView.removeGestureRecognizer(self.tapGesture)
                self.configure()
            }
        }
    }
}
