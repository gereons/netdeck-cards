//
//  Card+Map.swift
//
//  Created by Gereon Steffens on 04.10.17.
//
//  conversion maps for revised core -> old cards and old cards -> revised core

import Foundation

// MARK: - constants
extension Card {
    static let restricted = " 🦄"
    static let banned = " 🚫"
    static let unique = " ⬩"
    
    // identities we need to handle
    static let customBiotics            = "03002"    // no jinteki cards
    static let theProfessor             = "03029"    // first copy of each program has influence 0
    static let andromeda                = "02083"    // 9 card starting hand
    
    // alliance cards with special influence rules
    static let mumbaTemple              = "10018"    // 0 inf if <= 15 ice in deck
    static let museumOfHistory          = "10019"    // 0 inf if >= 50 cards in deck
    static let padFactory               = "10038"    // 0 inf if 3 pad campaigns in deck
    static let mumbadVirtualTour        = "10076"    // 0 inf if >= 7 assets in deck
    
    // alliance-based: 0 inf if >= 6 non-alliance cards of same faction in deck
    static let productRecall            = "10029"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let jeevesModelBioroid       = "10067"    // 0 inf if >= 6 non-alliance HB cards in deck
    static let ramanRai                 = "10068"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let heritageCommittee        = "10013"    // 0 inf if >= 6 non-alliance Jinteki cards in deck
    static let salemsHospitality        = "10071"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let ibrahimSalem             = "10109"    // 0 inf if >= 6 non-alliance NBN cards in deck
    static let executiveSearchFirm      = "10072"    // 0 inf if >= 6 non-alliance Weyland cards in deck
    static let consultingVisit          = "10094"    // 0 inf if >= 6 non-alliance Weyland cards in deck
    
    static let alliance6 = Set([
        productRecall, jeevesModelBioroid,
        ramanRai, heritageCommittee,
        salemsHospitality, ibrahimSalem,
        executiveSearchFirm, consultingVisit
    ])
    
    static let padCampaign              = "01109"    // needed for pad factory
    static let padCampaignCore2         = "20128"    // ditto
    
    // NAPD Most Wanted List
    static let parasite             = "01012"
    static let yog_0                = "01014"
    static let wyldside             = "01016"
    static let desperado            = "01024"
    static let astroscript          = "01081"
    static let breakingNews         = "01082"
    static let sansanCityGrid       = "01092"
    static let eli_1                = "02110"
    static let cloneChip            = "03038"
    static let prepaidVoicepad      = "04029"
    static let blackmail            = "04089"
    static let napdContract         = "04119"
    static let d4v1d                = "06033"
    static let architect            = "06061"
    static let cerberusH1           = "06099"
    static let faust                = "08061"
    static let ddos                 = "08103"
    static let bioEthicsAssociation = "10050"
    static let sensieActorsUnion    = "10053"
    static let mumbadCityHall       = "10055"
    static let rumorMill            = "11022"
    static let temüjinContract      = "11026"
    static let friendsInHighPlaces  = "11090"
    static let şifr                 = "11101"
    static let aaronMarrón          = "11106"
    
    // Ban/Restriced List
    static let levyARLabAccess      = "03035"
    static let motherGoddess        = "06010"
    static let filmCritic           = "08086"
    static let gangSign             = "08067"
    static let globalFoodInitiative = "09026"
    static let employeeStrike       = "09053"
    static let cloneSuffrageMovement = "10049"
    static let fairchild_3          = "11049"
    static let tapwrm               = "11104"
    static let violetLevelClearance = "11111"
    static let inversificator       = "12048"
    static let obokataProtocol      = "12070"
    static let whampoaReclamation   = "12079"
    static let blooMoose            = "12089"
    static let salvagedVanadisArmory = "12103"
    static let brainRewiring        = "13029"
    static let estelleMoon          = "13032"
    static let hunterSeeker         = "13051"
    static let magnumOpus           = "20050"
    static let aesopsPawnshop       = "20052"
}

// MARK: - NAPD MWL
extension Card {
    // dictonaries of code -> penalty for each MWL version
    private static let mostWantedLists: [MWL: MostWantedList] = [
        // MWL v1.0, introduced in Tournament Rules 3.0.2, valid from 2016-02-01 until 2016-07-31
        .v1_0: MostWantedList(penalties:
            [ cerberusH1: 1, cloneChip: 1, desperado: 1, parasite: 1, prepaidVoicepad: 1, yog_0: 1,
              architect: 1, astroscript: 1, eli_1: 1, napdContract: 1, sansanCityGrid: 1 ]),
        
        // MWL v1.1, introduced in Tournament Regulations v1.1, valid from 2016-08-01 until 2017-04-11
        .v1_1: MostWantedList(penalties:
            [ cerberusH1: 1, cloneChip: 1, d4v1d: 1, desperado: 1, faust: 1, parasite: 1, prepaidVoicepad: 1, wyldside: 1, yog_0: 1,
              architect: 1, breakingNews: 1, eli_1: 1, mumbaTemple: 1, napdContract: 1, sansanCityGrid: 1 ]),
        
        // MWL v1.2, introduced in NAPD Most Wanted List v1.2, valid from 2017-04-12 until 2017-09-30
        .v1_2: MostWantedList(penalties:
            [ cerberusH1: 1, cloneChip: 1, d4v1d: 1, parasite: 1, temüjinContract: 1, wyldside: 1, yog_0: 1,
              architect: 1, bioEthicsAssociation: 1, breakingNews: 1, mumbadCityHall: 1, mumbaTemple: 1, napdContract: 1, sansanCityGrid: 1,
              blackmail: 3, ddos: 3, faust: 3, rumorMill: 3, şifr: 3,
              sensieActorsUnion: 3 ]),
        
        // MWL v2.0, introduced in NAPD Most Wanted List v2.0, valid from 2017-10-01 until 2018-02-25
        .v2_0: MostWantedList(
            runnerBanned: [ aaronMarrón, blooMoose, faust, rumorMill, salvagedVanadisArmory, şifr, temüjinContract ],
            runnerRestricted: [ aesopsPawnshop, cloneChip, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, magnumOpus ],
            corpBanned: [ cloneSuffrageMovement, friendsInHighPlaces, mumbadCityHall, sensieActorsUnion ],
            corpRestricted: [bioEthicsAssociation, estelleMoon, fairchild_3, globalFoodInitiative, hunterSeeker, mumbaTemple, museumOfHistory, obokataProtocol ]),

        // MWL v2.1, introduced in NAPD Most Wanted List v2.1, valid from 2018-02-26
        .v2_1: MostWantedList(
            runnerBanned: [ aaronMarrón, blooMoose, faust, salvagedVanadisArmory, şifr, temüjinContract ],
            runnerRestricted: [ aesopsPawnshop, cloneChip, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, magnumOpus, rumorMill, tapwrm ],
            corpBanned: [ cloneSuffrageMovement, friendsInHighPlaces, sensieActorsUnion, violetLevelClearance ],
            corpRestricted: [bioEthicsAssociation, brainRewiring, estelleMoon, fairchild_3, globalFoodInitiative, hunterSeeker, motherGoddess, mumbaTemple, mumbadCityHall, museumOfHistory, obokataProtocol, whampoaReclamation ]),

        // MWL v2.2, introduced in NAPD Most Wanted List v2.2, valid from 2018-08-??
        .v2_2: MostWantedList(
            runnerBanned: [ aaronMarrón, blooMoose, faust, salvagedVanadisArmory, şifr, temüjinContract ],
            runnerRestricted: [ aesopsPawnshop, cloneChip, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, magnumOpus, rumorMill, tapwrm ],
            corpBanned: [ cloneSuffrageMovement, friendsInHighPlaces, sensieActorsUnion, violetLevelClearance ],
            corpRestricted: [bioEthicsAssociation, brainRewiring, estelleMoon, fairchild_3, globalFoodInitiative, hunterSeeker, motherGoddess, mumbaTemple, mumbadCityHall, museumOfHistory, obokataProtocol, whampoaReclamation ])
    ]
    
    func mwlPenalty(_ mwl: MWL) -> Int {
        guard let penalties = Card.mostWantedLists[mwl]?.penalties else {
            return 0
        }
        
        return penalties[self.code] ?? 0
    }
    
    func banned(_ mwl: MWL) -> Bool {
        guard let banned = Card.mostWantedLists[mwl]?.banned else {
            return false
        }
        return banned.contains(self.code)
    }
    
    func restricted(_ mwl: MWL) -> Bool {
        guard let restricted = Card.mostWantedLists[mwl]?.restricted else {
            return false
        }
        return restricted.contains(self.code)
    }
}

extension Card {
    
    func displayName(_ mwl: MWL, count: Int? = nil) -> String {
        let unique = self.unique ? Card.unique : ""
        let restricted = self.restricted(mwl) ? Card.restricted : ""
        let banned = self.banned(mwl) ? Card.banned : ""

        if let c = count {
            return "\(c)× \(self.name)\(unique)\(restricted)\(banned)"
        } else {
            return "\(self.name)\(unique)\(restricted)\(banned)"
        }
    }
}

// MARK: - aliases
extension Card {
    static let aliases = [
        ("01044", "Mopus"),     // Magnum Opus
        ("01092", "SSCG"),      // Sansan City Grid
        ("02069", "Mr. Phones"),// Underworld Contact
        ("02079", "OAI"),       // Oversight AI
        ("02085", "HQI"),       // HQ Interface
        ("02107", "RDI"),       // R&D Interface
        ("03035", "LARLA"),     // Levy AR Lab Access
        ("03044", "CyCy"),      // Cyber-Cypher
        ("03049", "Proco"),     // Professional Contacts
        ("04029", "PPVP"),      // Prepaid Voicepad
        ("05039", "SW35"),      // Unreg. s&w '35
        ("05039", "USW35"),
        ("06033", "David"),     // D4v1d
        ("07054", "QPT"),       // Qianju PT
        ("08003", "Pancakes"),  // Adjusted Chronotype
        ("08009", "Baby"),      // Symmetrical Visage
        ("08034", "Franklin"),  // Crick
        ("08086", "Anita"),     // Film Critic
        ("09007", "Kitty"),     // Quantum Predictive Model
        ("10043", "Polop"),     // Political Operative
        ("10108", "FIRS"),      // Full Immersion RecStudio
        ("11074", "Penguins"),  // Hasty Relocation
        ("11094", "IPB"),       // IP Block
        ("12088", "NNK"),       // Na'Not'K
        ("12088", "Nanotek"),
        ("12088", "Nanotech"),
        ("12104", "Turtle"),    // Aumakua
        ("12115", "ARES"),      // AR-Enhanced Security
        ("13038", "UVC"),       // Ultraviolet Clearance
        ("21101", "Zero"),      // Zer0
    ]
}

// MARK: - cropping
extension Card {
    var cropY: Double {
        return Card.cropValues[self.type] ?? 0.0
    }
    
    private static let cropValues: [CardType: Double] = [
        .agenda: 15.0,
        .asset: 20.0,
        .event: 10.0,
        .identity: 12.0,
        .operation: 10.0,
        .hardware: 18.0,
        .ice: 209.0,
        .program: 8.0,
        .resource: 11.0,
        .upgrade: 22.0
    ]
    
}

// MARK: - revised core set mapping
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
        let m = Dictionary(uniqueKeysWithValues: revisedToOriginal.map { ($1, $0) })
        return m
    }()
}
