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
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}

final class MWLSelection {

    @discardableResult
    static func show(_ setter: LegalitySetter, _ button: UIBarButtonItem? = nil, deck: Deck) -> UIAlertController {
        let actionSheet = MWLSelection.createAlert(for: deck, on: setter, button)

        if let button = button {
            let popover = actionSheet.popoverPresentationController
            popover?.barButtonItem = button
            popover?.permittedArrowDirections = .down

            actionSheet.view.layoutIfNeeded()
        }
        setter.present(actionSheet, animated: false, completion: nil)

        return actionSheet
    }

    private static func createAlert(for deck: Deck, on setter: LegalitySetter, _ button: UIBarButtonItem?) -> UIAlertController {
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)

        alert.addAction(UIAlertAction(title: "Casual".localized().checked(deck.legality == .casual)) { action in
            setter.setLegality(DeckLegality.casual)
        })

        let firstStandard = MWLManager.firstStandardIndex
        let oldMwl = deck.mwl > 0 && deck.legality.mwl < firstStandard

        alert.addAction(UIAlertAction(title: "Older MWLs".localized().checked(oldMwl)) { action in
            createAlertForOldVersions(for: deck, on: setter, button)
        })

        for index in firstStandard ..< MWLManager.count {
            let list = MWLManager.mwlBy(index)
            alert.addAction(UIAlertAction(title: list.name.localized().checked(deck.legality == index)) { action in
                setter.setLegality(DeckLegality.standard(mwl: index))
            })
        }

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

    private static func createAlertForOldVersions(for deck: Deck, on setter: LegalitySetter, _ button: UIBarButtonItem?) {
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)

        for index in 1 ..< MWLManager.firstStandardIndex {
            let mwl = MWLManager.mwlBy(index)

            alert.addAction(UIAlertAction(title: mwl.name.localized().checked(deck.mwl == index)) { action in
                setter.setLegality(DeckLegality.standard(mwl: index))
            })
        }

        alert.addAction(UIAlertAction.actionSheetCancel() { action in
            setter.legalityCancelled()
        })

        if let button = button {
            let popover = alert.popoverPresentationController
            popover?.barButtonItem = button
            popover?.permittedArrowDirections = .down

            alert.view.layoutIfNeeded()
        }
        setter.present(alert, animated: false, completion: nil)
    }
}
