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

@objc enum NRRole: Int {
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
    case Type           // sort by type, then alpha
    case FactionType    // sort by faction, then type, then alpha
    case SetType        // sort by set, then type, then alpha
    case SetNum         // sort by set, then number in set
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
    case Date
    case Faction
    case A_Z
}

@objc enum NRCardView: Int {
    case Image
    case LargeTable
    case SmallTable
}

@objc enum NRBrowserSort: Int {
    case Type
    case Faction
    case TypeFaction
    case Set
    case SetFaction
    case SetType
    case SetNumber
}

@objc enum NRCycle: Int {
    case None = -1
    case CoreDeluxe // core, c&c, h&p, o&c, d&d
    case Genesis
    case Spin
    case Lunar
    case SanSan
    case Mumbad
    case Flashpoint
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
