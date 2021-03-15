//
//  StartViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.02.18.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

protocol StartViewController {
    func addNewDeck(_ role: Role)
    func openBrowser()
}