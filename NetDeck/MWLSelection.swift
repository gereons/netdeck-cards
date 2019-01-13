//
//  MWLSelection.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.01.18.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

protocol LegalitySetter {
    func setLegality(_ legality: DeckLegality)
    func legalityCancelled()
}

class MWLSelection {
    static func createAlert(for deck: Deck, on setter: LegalitySetter) -> UIAlertController {
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)

        alert.addAction(UIAlertAction(title: "Casual".localized().checked(deck.legality == .casual)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.none))
        })

        alert.addAction(UIAlertAction(title: "MWL v1.0".localized().checked(deck.legality == .v1_0)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v1_0))
        })

        alert.addAction(UIAlertAction(title: "MWL v1.1".localized().checked(deck.legality == .v1_1)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v1_1))
        })

        alert.addAction(UIAlertAction(title: "MWL v1.2".localized().checked(deck.legality == .v1_2)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v1_2))
        })

        alert.addAction(UIAlertAction(title: "MWL v2.0".localized().checked(deck.legality == .v2_0)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v2_0))
        })

        alert.addAction(UIAlertAction(title: "MWL v2.1".localized().checked(deck.legality == .v2_1)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v2_1))
        })

        alert.addAction(UIAlertAction(title: "MWL v2.2".localized().checked(deck.legality == .v2_2)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v2_2))
        })

        alert.addAction(UIAlertAction(title: "MWL v3.0".localized().checked(deck.legality == .v3_0)) { action in
            setter.setLegality(DeckLegality.standard(mwl: MWL.v3_0))
        })

        alert.addAction(UIAlertAction(title: "1.1.1.1".localized().checked(deck.legality == .onesies)) { action in
            setter.setLegality(DeckLegality.onesies)
        })

        alert.addAction(UIAlertAction(title: "Modded".localized().checked(deck.legality == .modded)) { action in
            setter.setLegality(DeckLegality.modded)
        })

        alert.addAction(UIAlertAction(title: "Cache Refresh".localized().checked(deck.legality == .cacheRefresh)) { action in
            setter.setLegality(DeckLegality.cacheRefresh)
        })

        alert.addAction(UIAlertAction.actionSheetCancel() { action in
            setter.legalityCancelled()
        })

        return alert
    }
}
