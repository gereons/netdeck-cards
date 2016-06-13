//
//  Types.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc enum NRCardType: Int {
    case None = -1
    case Identity

    // corp
    case Agenda, Asset, Upgrade, Operation, Ice

    // runner
    case Event, Hardware, Resource, Program
}

@objc(NRRole) enum NRRole: Int {
    case None = -1
    case Runner, Corp
}

@objc enum NRFaction: Int {
    case None = -1
    case Neutral
    
    case HaasBioroid, Weyland, NBN, Jinteki
    
    case Anarch, Shaper, Criminal
    
    case Adam, Apex, SunnyLebeau
}

@objc enum NRDeckState: Int {
    case None = -1
    case Active, Testing, Retired
}

@objc enum NRDeckSort: Int {
    case ByType           // sort by type, then alpha
    case ByFactionType    // sort by faction, then type, then alpha
    case BySetType        // sort by set, then type, then alpha
    case BySetNum         // sort by set, then number in set
}

@objc enum NRSearchScope: Int {
    case All
    case Name
    case Text
}

@objc enum NRDeckSearchScope: Int {
    case All
    case Name
    case Identity
    case Card
}

@objc enum NRDeckListSort: Int {
    case ByDate
    case ByFaction
    case ByName
}

@objc enum NRCardView: Int {
    case Image
    case LargeTable
    case SmallTable
}

@objc enum NRBrowserSort: Int {
    case ByType
    case ByFaction
    case ByTypeFaction
    case BySet
    case BySetFaction
    case BySetType
    case BySetNumber
}

@objc enum NRImportSource: Int {
    case None
    case Dropbox
    case NetrunnerDb
}

@objc enum NRFilter: Int {
    case All
    case Runner
    case Corp
}
