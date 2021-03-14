//
//  CollectionViewSectionHeader.swift
//  NetDeck
//
//  Created by Gereon Steffens on 30.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class CollectionViewSectionHeader: UICollectionReusableView {

    @IBOutlet weak var title: UILabel!

    static func nib() -> UINib {
        return UINib(nibName: "CollectionViewSectionHeader", bundle: nil)
    }
}
