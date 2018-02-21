//
//  MWLSelection.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.01.18.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

protocol LegalitySetter {
    func setLegality(_ mwl: MWL, cacheRefresh: Bool, onesies: Bool)
}

class MWLSelection {
    static func createAlert(for deck: Deck, on setter: LegalitySetter) -> UIAlertController {
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)

        alert.addAction(UIAlertAction(title: "Casual".localized().checked(deck.mwl == .none && !deck.onesies)) { action in
            setter.setLegality(.none, cacheRefresh: deck.cacheRefresh, onesies: false)
        })
        alert.addAction(UIAlertAction(title: "MWL v1.0".localized().checked(deck.mwl == .v1_0)) { action in
            setter.setLegality(.v1_0, cacheRefresh: deck.cacheRefresh, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "MWL v1.1".localized().checked(deck.mwl == .v1_1)) { action in
            setter.setLegality(.v1_1, cacheRefresh: deck.cacheRefresh, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "MWL v1.2".localized().checked(deck.mwl == .v1_2)) { action in
            setter.setLegality(.v1_2, cacheRefresh: deck.cacheRefresh, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "MWL v2.0".localized().checked(deck.mwl == .v2_0)) { action in
            setter.setLegality(.v2_0, cacheRefresh: false, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "MWL v2.1".localized().checked(deck.mwl == .v2_1)) { action in
            setter.setLegality(.v2_1, cacheRefresh: false, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "1.1.1.1".localized().checked(deck.onesies)) { action in
            setter.setLegality(.none, cacheRefresh: false, onesies: true)
        })

        alert.addAction(UIAlertAction(title: "Cache Refresh".localized().checked(deck.cacheRefresh)) { action in
            setter.setLegality(MWL.latest, cacheRefresh: !deck.cacheRefresh, onesies: false)
        })

        alert.addAction(UIAlertAction.actionSheetCancel(nil))

        return alert
    }
}
