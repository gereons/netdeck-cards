//
//  Card+Map.swift
//
//  Created by Gereon Steffens on 04.10.17.
//
//  conversion maps for revised core -> old cards and old cards -> revised core

import Foundation

extension Card {
    static let revisedToOriginal = [
        "20001": "04041", // Reina Roja
        "20002": "01003", // Demolition Run
        "20003": "02101", // Retrieval Run
        "20004": "04101", // Singularity
        "20005": "01004", // Stimhack
        "20006": "01005", // Cyberfeeder
        "20007": "02002", // Spinal Modem
        "20008": "02102", // Darwin
        "20009": "01008", // Datasucker
        "20010": "02062", // Force of Nature
        "20011": "02003", // Imp
        "20012": "04082", // Hemorrhage
        "20013": "01011", // Mimic
        "20014": "02004", // Morning Star
        "20015": "01015", // Ice Carver
        "20016": "02022", // Liberated Account
        "20017": "02063", // Scrubber
        "20018": "02082", // Xanadu
        "20019": "01017", // Gabriel Santiago
        "20020": "01019", // Easy Mark
        "20021": "02043", // Emergency Shutdown
        "20022": "01020", // Forged Activation Orders
        "20023": "01021", // Inside Job
        "20024": "01022", // Special Order
        "20025": "02064", // Doppelgänger
        "20026": "02085", // HQ Interface
        "20027": "01025", // Aurora
        "20028": "02104", // Faerie
        "20029": "01026", // Femme Fatale
        "20030": "02006", // Peacock
        "20031": "02086", // Pheromones
        "20032": "01028", // Sneakdoor Beta
        "20033": "01029", // Bank Job
        "20034": "01030", // Crash Space
        "20035": "04106", // Fall Guy
        "20036": "02105", // Mr. Li
        "20037": "02046", // Chaos Theory
        "20038": "01034", // Diesel
        "20039": "02106", // Indexing
        "20040": "01035", // Modded
        "20041": "02026", // Notoriety
        "20042": "02047", // Test Run
        "20043": "01036", // The Maker's Eye
        "20044": "01037", // Tinkering
        "20045": "02048", // Dinosaurus
        "20046": "01039", // Rabbit Hole
        "20047": "01040", // The Personal Touch
        "20048": "01042", // Battering Ram
        "20049": "01043", // Gordian Blade
        "20050": "01044", // Magnum Opus
        "20051": "01046", // Pipeline
        "20052": "01047", // Aesop's Pawnshop
        "20053": "02067", // All-nighter
        "20054": "01048", // Sacrificial Construct
        "20055": "01049", // Infiltration
        "20056": "01050", // Sure Gamble
        "20057": "02028", // Dyson Mem Chip
        "20058": "01051", // Crypsis
        "20059": "01053", // Armitage Codebusting
        "20060": "02069", // Underworld Contact
        "20061": "02010", // Stronger Together
        "20062": "04010", // Project Ares
        "20063": "02051", // Project Vitruvius
        "20064": "01056", // Adonis Campaign
        "20065": "01057", // Aggressive Secretary
        "20066": "01061", // Heimdall 1.0
        "20067": "04051", // Hudson 1.0
        "20068": "01062", // Ichi 1.0
        "20069": "01064", // Rototurret
        "20070": "01063", // Viktor 1.0
        "20071": "01058", // Archived Memories
        "20072": "01059", // Biotic Labor
        "20073": "02070", // Green Level Clearance
        "20074": "01060", // Shipment from MirrorMorph
        "20075": "02013", // Ash 2X3ZB9CY
        "20076": "04091", // Strongbox
        "20077": "01093", // Building a Better World
        "20078": "01094", // Hostile Takeover
        "20079": "02018", // Project Atlas
        "20080": "04036", // The Cleaners
        "20081": "02118", // Dedicated Response Team
        "20082": "04037", // Elizabeth Mills
        "20083": "04099", // GRNDL Refinery
        "20084": "01101", // Archer
        "20085": "02019", // Caduceus
        "20086": "01102", // Hadrian's Wall
        "20087": "04117", // Hive
        "20088": "01103", // Ice Wall
        "20089": "01104", // Shadow
        "20090": "01098", // Beanstalk Royalties
        "20091": "04079", // Punitive Counterstrike
        "20092": "01100", // Shipment from Kaguya
        "20093": "01067", // Personal Evolution
        "20094": "02014", // Braintrust
        "20095": "01068", // Nisei MK II
        "20096": "01069", // Project Junebug
        "20097": "02112", // Ronin
        "20098": "01070", // Snare!
        "20099": "04013", // Himitsu-Bako
        "20100": "01077", // Neural Katana
        "20101": "04033", // Swordsman
        "20102": "01078", // Wall of Thorns
        "20103": "02094", // Whirlpool
        "20104": "04093", // Yagura
        "20105": "04012", // Celebrity Gift
        "20106": "01072", // Neural EMP
        "20107": "02033", // Trick of Light
        "20108": "02095", // Hokusai Grid
        "20109": "01080", // Making News
        "20110": "02115", // Project Beale
        "20111": "04075", // TGTBT
        "20112": "01087", // Ghost Branch
        "20113": "01088", // Data Raven
        "20114": "02117", // Flare
        "20115": "02056", // Pop-up Window
        "20116": "01090", // Tollbooth
        "20117": "04096", // Wraparound
        "20118": "01083", // Anonymous Tip
        "20119": "01084", // Closed Accounts
        "20120": "01085", // Psychographics
        "20121": "01086", // SEA Source
        "20122": "01091", // Red Herrings
        "20123": "02097", // Bernice Mai
        "20124": "02080", // False Lead
        "20125": "01106", // Priority Requisition
        "20126": "01107", // Private Security Force
        "20127": "01108", // Melange Mining Corp.
        "20128": "01109", // PAD Campaign
        "20129": "01111", // Enigma
        "20130": "01112", // Hunter
        "20131": "01113", // Wall of Static
        "20132": "01110", // Hedge Fund
    ]

    static let originalToRevised: [String: String] = {
        var map = [String: String]()
        revisedToOriginal.enumerated().forEach { (offset, element) in
            map[element.value] = element.key
        }
        assert(map.count == revisedToOriginal.count, "count mismatch")
        return map
    }()
}
