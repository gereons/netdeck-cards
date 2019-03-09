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
    static let padCampaignSC19          = "25142"    // ditto
    static let padCampaigns = [ padCampaign, padCampaignCore2, padCampaignSC19 ]

    /*
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
    
    // Ban/Restricted List
    static let cerebralImaging      = "03001"
    static let levyARLabAccess      = "03035"
    static let motherGoddess        = "06010"
    static let filmCritic           = "08086"
    static let gangSign             = "08067"
    static let hyperdriver          = "08070"
    static let _24_7_newsCycle      = "09019"
    static let globalFoodInitiative = "09026"
    static let employeeStrike       = "09053"
    static let cloneSuffrageMovement = "10049"
    static let fairchild_3          = "11049"
    static let potentialUnleashed   = "11054"
    static let tapwrm               = "11104"
    static let violetLevelClearance = "11111"
    static let bryanStinson         = "11117"
    static let madDash              = "12008"
    static let inversificator       = "12048"
    static let obokataProtocol      = "12070"
    static let whampoaReclamation   = "12079"
    static let marsForMartians      = "12081"
    static let blooMoose            = "12089"
    static let salvagedVanadisArmory = "12103"
    static let brainRewiring        = "13029"
    static let estelleMoon          = "13032"
    static let skorpios             = "13041"
    static let hunterSeeker         = "13051"
    static let magnumOpus           = "20050"
    static let aesopsPawnshop       = "20052"
    static let zer0                 = "21101"
    static let surveyor             = "21118"
    static let watchTheWorldBurn    = "23100"
    static let commercialBankersGroup = "10054"
    static let paperclip            = "11024"
    static let hiredHelp            = "23101"
    static let mtiMwekundu          = "21114"
    static let excalibur            = "06111"
    static let crowdfunding         = "23013"
    static let dormComputer         = "08024"
    */
}

/*
// MARK: - NAPD MWL
extension Card {
    // dictionaries of code -> penalty for each MWL version
    private static let mostWantedLists: [MWL: MostWantedList] = [
        // MWL v1.0, introduced in Tournament Rules 3.0.2, valid from 2016-02-01 until 2016-07-31
        .v1_0: MostWantedList("NAPD_MWL_1.0", "MWL 1.0", 1,
            penalties:
            [ cerberusH1: 1, cloneChip: 1, desperado: 1, parasite: 1, prepaidVoicepad: 1, yog_0: 1,
              architect: 1, astroscript: 1, eli_1: 1, napdContract: 1, sansanCityGrid: 1 ]),
        
        // MWL v1.1, introduced in Tournament Regulations v1.1, valid from 2016-08-01 until 2017-04-11
        .v1_1: MostWantedList("NAPD_MWL_1.1", "MWL 1.1", 2,
            penalties:
            [ cerberusH1: 1, cloneChip: 1, d4v1d: 1, desperado: 1, faust: 1, parasite: 1, prepaidVoicepad: 1, wyldside: 1, yog_0: 1,
              architect: 1, breakingNews: 1, eli_1: 1, mumbaTemple: 1, napdContract: 1, sansanCityGrid: 1 ]),
        
        // MWL v1.2, introduced in NAPD Most Wanted List v1.2, valid from 2017-04-12 until 2017-09-30
        .v1_2: MostWantedList("NAPD_MWL_1.2", "MWL 1.2", 3,
            penalties:
            [ cerberusH1: 1, cloneChip: 1, d4v1d: 1, parasite: 1, temüjinContract: 1, wyldside: 1, yog_0: 1,
              architect: 1, bioEthicsAssociation: 1, breakingNews: 1, mumbadCityHall: 1, mumbaTemple: 1, napdContract: 1, sansanCityGrid: 1,
              blackmail: 3, ddos: 3, faust: 3, rumorMill: 3, şifr: 3,
              sensieActorsUnion: 3 ]),
        
        // MWL v2.0, introduced in NAPD Most Wanted List v2.0, valid from 2017-10-01 until 2018-02-25
        .v2_0: MostWantedList("NAPD_MWL_2.0", "MWL 2.0", 4,
            runnerBanned: [ aaronMarrón, blooMoose, faust, rumorMill, salvagedVanadisArmory, şifr, temüjinContract ],
            runnerRestricted: [ aesopsPawnshop, cloneChip, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, magnumOpus ],
            corpBanned: [ cloneSuffrageMovement, friendsInHighPlaces, mumbadCityHall, sensieActorsUnion ],
            corpRestricted: [bioEthicsAssociation, estelleMoon, fairchild_3, globalFoodInitiative, hunterSeeker, mumbaTemple, museumOfHistory, obokataProtocol ]),

        // MWL v2.1, introduced in NAPD Most Wanted List v2.1, valid from 2018-02-26
        .v2_1: MostWantedList("NAPD_MWL_2.1", "MWL 2.1", 5,
            runnerBanned: [ aaronMarrón, blooMoose, faust, salvagedVanadisArmory, şifr, temüjinContract ],
            runnerRestricted: [ aesopsPawnshop, cloneChip, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, magnumOpus, rumorMill, tapwrm ],
            corpBanned: [ cloneSuffrageMovement, friendsInHighPlaces, sensieActorsUnion, violetLevelClearance ],
            corpRestricted: [bioEthicsAssociation, brainRewiring, estelleMoon, fairchild_3, globalFoodInitiative, hunterSeeker, motherGoddess, mumbaTemple, mumbadCityHall, museumOfHistory, obokataProtocol, whampoaReclamation ]),

        // MWL v2.2, introduced in NAPD Most Wanted List v2.2, valid from 2018-09-06
        .v2_2: MostWantedList("NAPD_MWL_2.2", "MWL 2.2", 6,
            runnerBanned: [ aaronMarrón, blooMoose, faust, hyperdriver, marsForMartians, salvagedVanadisArmory, şifr, tapwrm, temüjinContract, zer0 ],
            runnerRestricted: [ aesopsPawnshop, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, madDash, magnumOpus, rumorMill ],
            corpBanned: [ _24_7_newsCycle, cerebralImaging, cloneSuffrageMovement, estelleMoon, friendsInHighPlaces, museumOfHistory, sensieActorsUnion ],
            corpRestricted: [ bioEthicsAssociation, brainRewiring, bryanStinson, globalFoodInitiative, hunterSeeker, motherGoddess, mumbaTemple, mumbadCityHall, obokataProtocol, potentialUnleashed, skorpios, surveyor, violetLevelClearance, whampoaReclamation ]),

        // MWL v3.0, introduced in NISEI System Core 2019, valid from 2018-12-21
        .v3_0: MostWantedList("standard-mwl-3-0", "MWL 3.0", 7,
            runnerBanned: [ aaronMarrón, blooMoose, faust, hyperdriver, marsForMartians, salvagedVanadisArmory, şifr, tapwrm, temüjinContract, watchTheWorldBurn, zer0 ],
            runnerRestricted: [ aesopsPawnshop, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, madDash, paperclip, rumorMill ],
            corpBanned: [ _24_7_newsCycle, bryanStinson, cerebralImaging, cloneSuffrageMovement, friendsInHighPlaces, hiredHelp, museumOfHistory, sensieActorsUnion ],
            corpRestricted: [ bioEthicsAssociation, commercialBankersGroup, excalibur, globalFoodInitiative, potentialUnleashed, motherGoddess, mtiMwekundu,
                              mumbaTemple, mumbadCityHall, obokataProtocol, surveyor, violetLevelClearance, whampoaReclamation]),

        // MWL v3.1, introduced in NISEI System Core 2019, valid from 2019-02-22
        .v3_1: MostWantedList("standard-mwl-3.1", "MWL 3.1", 8,
            runnerBanned: [ aaronMarrón, blooMoose, faust, hyperdriver, marsForMartians, salvagedVanadisArmory, şifr, tapwrm, temüjinContract, watchTheWorldBurn, zer0 ],
            runnerRestricted: [ aesopsPawnshop, crowdfunding, dormComputer, employeeStrike, filmCritic, gangSign, inversificator, levyARLabAccess, madDash, paperclip, rumorMill ],
            corpBanned: [ potentialUnleashed, _24_7_newsCycle, bryanStinson, cerebralImaging, cloneSuffrageMovement, friendsInHighPlaces, hiredHelp, museumOfHistory, sensieActorsUnion ],
            corpRestricted: [ bioEthicsAssociation, commercialBankersGroup, excalibur, globalFoodInitiative, motherGoddess, mtiMwekundu,
                mumbaTemple, mumbadCityHall, obokataProtocol, surveyor, violetLevelClearance, whampoaReclamation])
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
*/

extension Card {
    func mwlPenalty(_ mwl: Int) -> Int {
        return 0
    }

    func banned(_ mwl: Int) -> Bool {
        return false
    }

    func restricted(_ mwl: Int) -> Bool {
        return false
    }
}

extension Card {
    func displayName(_ mwl: Int, count: Int? = nil) -> String {
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
    // FIXME: merge the two maps
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

    static let sc19toRevised = [
        "25001": "20001", // Reina Roja
        "25002": "06052", // Quetzal
        "25003": "04102", // Queen's Gambit
        "25004": "04081", // Quest Completed
        "25005": "20003", // Retrieval Run
        "25006": "10001", // Run Amok
        "25007": "20005", // Stimhack
        "25008": "20006", // Cyberfeeder
        "25009": "22004", // Patchwork
        "25010": "01007", // Corroder
        "25011": "20009", // Datasucker
        "25012": "20010", // Force of Nature
        "25013": "20011", // Imp
        "25014": "06014", // Lamprey
        "25015": "20013", // Mimic
        "25016": "20015", // Ice Carver
        "25017": "20016", // Liberated Account
        "25018": "20017", // Scrubber
        "25019": "20018", // Xanadu
        "25020": "20019", // Gabriel Santiago
        "25021": "06095", // Leela Patel
        "25022": "08023", // Career Fair
        "25023": "20020", // Easy Mark
        "25024": "20021", // Emergency Shutdown
        "25025": "04004", // Hostage
        "25026": "20023", // Inside Job
        "25027": "05035", // Legwork
        "25028": "02084", // Networking
        "25029": "13003", // Spear Phishing
        "25030": "20024", // Special Order
        "25031": "20026", // HQ Interface
        "25032": "22010", // Paragon
        "25033": "13006", // Abagnale
        "25034": "13008", // Demara
        "25035": "20028", // Faerie
        "25036": "20029", // Femme Fatale
        "25037": "20032", // Sneakdoor Beta
        "25038": "20033", // Bank Job
        "25039": "01031", // Data Dealer
        "25040": "20037", // Chaos Theory
        "25041": "03028", // Rielle "Kit" Peddler
        "25042": "20038", // Diesel
        "25043": "20040", // Modded
        "25044": "20041", // Notoriety
        "25045": "20042", // Test Run
        "25046": "20043", // The Maker's Eye
        "25047": "20044", // Tinkering
        "25048": "01038", // Akamatsu Mem Chip
        "25049": "20045", // Dinosaurus
        "25050": "02107", // R&D Interface
        "25051": "03040", // Atman
        "25052": "20048", // Battering Ram
        "25053": "02066", // Deus X
        "25054": "20049", // Gordian Blade
        "25055": "20051", // Pipeline
        "25056": "20052", // Aesop's Pawnshop
        "25057": "03051", // Ice Analyzer
        "25058": "03049", // Professional Contacts
        "25059": "20056", // Sure Gamble
        "25060": "03052", // Dirty Laundry
        "25061": "20058", // Crypsis
        "25062": "20059", // Armitage Codebusting
        "25063": "06120", // Earthrise Hotel
        "25064": "04009", // John Masanori
        "25065": "02091", // Kati Jones
        "25066": "20061", // Stronger Together
        "25067": "13028", // Seidr Laboratories
        "25068": "20063", // Project Vitruvius
        "25069": "13031", // Successful Field Test
        "25070": "20064", // Adonis Campaign
        "25071": "20065", // Aggressive Secretary
        "25072": "13033", // Marilyn Campaign
        "25073": "02110", // Eli 1.0
        "25074": "20066", // Heimdall 1.0
        "25075": "20068", // Ichi 1.0
        "25076": "20069", // Rototurret
        "25077": "08033", // Turing
        "25078": "20070", // Viktor 1.0
        "25079": "20071", // Archived Memories
        "25080": "20072", // Biotic Labor
        "25081": "04090", // Blue Level Clearance
        "25082": "20075", // Ash 2X3ZB9CY
        "25083": "13040", // Mason Bellamy
        "25084": "20093", // Personal Evolution
        "25085": "02031", // Replicating Perfection
        "25086": "02032", // Fetal AI
        "25087": "20095", // Nisei MK II
        "25088": "05006", // Philotic Entanglement
        "25089": "20096", // Project Junebug
        "25090": "20097", // Ronin
        "25091": "20098", // Snare!
        "25092": "04054", // Sundew
        "25093": "20099", // Himitsu-Bako
        "25094": "06003", // Lotus Field
        "25095": "20100", // Neural Katana
        "25096": "20101", // Swordsman
        "25097": "04074", // Tsurugi
        "25098": "20102", // Wall of Thorns
        "25099": "20104", // Yagura
        "25100": "20105", // Celebrity Gift
        "25101": "20106", // Neural EMP
        "25102": "20107", // Trick of Light
        "25103": "20108", // Hokusai Grid
        "25104": "20109", // Making News
        "25105": "09003", // Spark Agency
        "25106": "08094", // Explode-a-palooza
        "25107": "20110", // Project Beale
        "25108": "06086", // Daily Business Show
        "25109": "20112", // Ghost Branch
        "25110": "02055", // Marked Accounts
        "25111": "06066", // Reversed Accounts
        "25112": "20113", // Data Raven
        "25113": "20114", // Flare
        "25114": "20115", // Pop-up Window
        "25115": "20116", // Tollbooth
        "25116": "20117", // Wraparound
        "25117": "20119", // Closed Accounts
        "25118": "20120", // Psychographics
        "25119": "20121", // SEA Source
        "25120": "08115", // Product Placement
        "25121": "20122", // Red Herrings
        "25122": "20077", // Building a Better World
        "25123": "06068", // Blue Sun
        "25124": "20078", // Hostile Takeover
        "25125": "08058", // Oaktown Renovation
        "25126": "20079", // Project Atlas
        "25127": "08078", // Contract Killer
        "25128": "20082", // Elizabeth Mills
        "25129": "08117", // Public Support
        "25130": "20084", // Archer
        "25131": "20085", // Caduceus
        "25132": "20086", // Hadrian's Wall
        "25133": "13050", // Hortum
        "25134": "20088", // Ice Wall
        "25135": "08079", // Spiderweb
        "25136": "20090", // Beanstalk Royalties
        "25137": "02079", // Oversight AI
        "25138": "20091", // Punitive Counterstrike
        "25139": "06048", // Crisium Grid
        "25140": "13053", // Paper Trail
        "25141": "20125", // Priority Requisition
        "25142": "20128", // PAD Campaign
        "25143": "20129", // Enigma
        "25144": "20130", // Hunter
        "25145": "20131", // Wall of Static
        "25146": "20132", // Hedge Fund
        "25147": "13057", // IPO
    ]

    static let revisedToSC19: [String: String] = {
        let m = Dictionary(uniqueKeysWithValues: sc19toRevised.map { ($1, $0) })
        return m
    }()

    static let __old2new = [
        "01004": "25007", "01005": "25008", "01007": "25010", "01008": "25011",
        "01011": "25015", "01015": "25016", "01017": "25020", "01019": "25023",
        "01021": "25026", "01022": "25030", "01026": "25036", "01028": "25037",
        "01029": "25038", "01031": "25039", "01034": "25042", "01035": "25043",
        "01036": "25046", "01037": "25047", "01038": "25048", "01042": "25052",
        "01043": "25054", "01046": "25055", "01047": "25056", "01050": "25059",
        "01051": "25061", "01053": "25062", "01056": "25070", "01057": "25071",
        "01058": "25079", "01059": "25080", "01061": "25074", "01062": "25075",
        "01063": "25078", "01064": "25076", "01067": "25084", "01068": "25087",
        "01069": "25089", "01070": "25091", "01072": "25101", "01077": "25095",
        "01078": "25098", "01080": "25104", "01084": "25117", "01085": "25118",
        "01086": "25119", "01087": "25109", "01088": "25112", "01090": "25115",
        "01091": "25121", "01093": "25122", "01094": "25124", "01098": "25136",
        "01101": "25130", "01102": "25132", "01103": "25134", "01106": "25141",
        "01109": "25142", "01110": "25146", "01111": "25143", "01112": "25144",
        "01113": "25145", "02003": "25013", "02010": "25066", "02013": "25082",
        "02018": "25126", "02019": "25131", "02022": "25017", "02026": "25044",
        "02031": "25085", "02032": "25086", "02033": "25102", "02043": "25024",
        "02046": "25040", "02047": "25045", "02048": "25049", "02051": "25068",
        "02055": "25110", "02056": "25114", "02062": "25012", "02063": "25018",
        "02066": "25053", "02079": "25137", "02082": "25019", "02084": "25028",
        "02085": "25031", "02091": "25065", "02095": "25103", "02101": "25005",
        "02104": "25035", "02107": "25050", "02110": "25073", "02112": "25090",
        "02115": "25107", "02117": "25113", "03028": "25041", "03040": "25051",
        "03049": "25058", "03051": "25057", "03052": "25060", "04004": "25025",
        "04009": "25064", "04012": "25100", "04013": "25093", "04033": "25096",
        "04037": "25128", "04041": "25001", "04054": "25092", "04074": "25097",
        "04079": "25138", "04081": "25004", "04090": "25081", "04093": "25099",
        "04096": "25116", "04102": "25003", "05006": "25088", "05035": "25027",
        "06003": "25094", "06014": "25014", "06048": "25139", "06052": "25002",
        "06066": "25111", "06068": "25123", "06086": "25108", "06095": "25021",
        "06120": "25063", "08023": "25022", "08033": "25077", "08058": "25125",
        "08078": "25127", "08079": "25135", "08094": "25106", "08115": "25120",
        "08117": "25129", "09003": "25105", "10001": "25006", "13003": "25029",
        "13006": "25033", "13008": "25034", "13028": "25067", "13031": "25069",
        "13033": "25072", "13040": "25083", "13050": "25133", "13053": "25140",
        "13057": "25147", "20001": "25001", "20003": "25005", "20005": "25007",
        "20006": "25008", "20009": "25011", "20010": "25012", "20011": "25013",
        "20013": "25015", "20015": "25016", "20016": "25017", "20017": "25018",
        "20018": "25019", "20019": "25020", "20020": "25023", "20021": "25024",
        "20023": "25026", "20024": "25030", "20026": "25031", "20028": "25035",
        "20029": "25036", "20032": "25037", "20033": "25038", "20037": "25040",
        "20038": "25042", "20040": "25043", "20041": "25044", "20042": "25045",
        "20043": "25046", "20044": "25047", "20045": "25049", "20048": "25052",
        "20049": "25054", "20051": "25055", "20052": "25056", "20056": "25059",
        "20058": "25061", "20059": "25062", "20061": "25066", "20063": "25068",
        "20064": "25070", "20065": "25071", "20066": "25074", "20068": "25075",
        "20069": "25076", "20070": "25078", "20071": "25079", "20072": "25080",
        "20075": "25082", "20077": "25122", "20078": "25124", "20079": "25126",
        "20082": "25128", "20084": "25130", "20085": "25131", "20086": "25132",
        "20088": "25134", "20090": "25136", "20091": "25138", "20093": "25084",
        "20095": "25087", "20096": "25089", "20097": "25090", "20098": "25091",
        "20099": "25093", "20100": "25095", "20101": "25096", "20102": "25098",
        "20104": "25099", "20105": "25100", "20106": "25101", "20107": "25102",
        "20108": "25103", "20109": "25104", "20110": "25107", "20112": "25109",
        "20113": "25112", "20114": "25113", "20115": "25114", "20116": "25115",
        "20117": "25116", "20119": "25117", "20120": "25118", "20121": "25119",
        "20122": "25121", "20125": "25141", "20128": "25142", "20129": "25143",
        "20130": "25144", "20131": "25145", "20132": "25146", "22004": "25009",
        "22010": "25032"
    ]
}
