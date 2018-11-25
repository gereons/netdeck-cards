//
//  DefaultsKeys.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.12.15.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    /// when to next check for app update
    static let nextUpdateCheck = DefaultsKey<Date?>("nextUpdateCheck")
    
    /// counter for deck names
    static let fileSequence  = DefaultsKey<Int>("fileSequence")
    
    /// last seen clipboard change count
    static let clipChangeCount = DefaultsKey<Int>("clipChangeCount")
    
    // ImageCache settings
    /// map of card code to Last-Modified
    static let lastModifiedCache = DefaultsKey<[String: String]?>("lastModified")
    /// map of card code to date (when to check for update)
    static let nextCheck = DefaultsKey<[String: Date]?>("nextCheck")
    /// list of known unavailable card images
    static let unavailableImages = DefaultsKey<[String]?>("unavailableImages")
    /// when next to check for these images
    static let unavailableImagesDate = DefaultsKey<Double?>("unavailableImagesDate")
    
    // Card data
    /// date of last download
    static let lastDownload = DefaultsKey<String>("lastDownload")
    /// date of next download
    static let nextDownload = DefaultsKey<String>("nextDownload")
    /// update interval in days
    static let updateInterval = DefaultsKey<Int>("updateInterval")
    /// auto-update?
    static let autoCardUpdates = DefaultsKey<Bool>("autoCardUpdates")
    /// card language
    static let language = DefaultsKey<String>("language")
    
    // Card selection
    /// use original Core Set?
    static let useCore = DefaultsKey<Bool>("use_core")
    /// number of core sets
    static let numOriginalCore = DefaultsKey<Int>("number_coresets")

    /// use revised Core Set?
    static let useCore2 = DefaultsKey<Bool>("use_core2")
     /// number of revised core sets
    static let numRevisedCore = DefaultsKey<Int>("number_revisedcoresets")

    /// is Data & Destiny selected/allowed?
    static let useDataDestiny = DefaultsKey<Bool>("use_dad")
    /// use Draft identities?
    static let useDraft = DefaultsKey<Bool>("use_draft")
    /// use NAPD multiplayer?
    static let useNapd = DefaultsKey<Bool>("use_napd")

    // Import/Export settings
    /// Dropbox enabled?
    static let useDropbox = DefaultsKey<Bool>("useDropbox")
    /// NetrunnerDB.com enabled?
    static let useNrdb = DefaultsKey<Bool>("useNrdb")
    static let nrdbLoggedin = DefaultsKey<Bool>("nrdbLoggedin")
    /// Jinteki.net enabled?
    static let useJintekiNet = DefaultsKey<Bool>("useJnet")

    // Saving options
    /// auto-save on every change?
    static let autoSave = DefaultsKey<Bool>("autoSave")
    /// auto-save to dropbox?
    static let autoSaveDropbox = DefaultsKey<Bool>("autoSaveDropbox")
    /// track editing history?
    static let autoHistory = DefaultsKey<Bool>("autoHistory")
    /// when manually saving, upload to nrdb automatically?
    static let nrdbAutosave = DefaultsKey<Bool>("nrdbAutoSave")

    /// create new decks as "Active"?
    static let createDeckActive = DefaultsKey<Bool>("createDeckActive")
    
    // filter and sorting for saved decks
    static let deckFilterType = DefaultsKey<Filter>("deckFilterType")
    static let deckFilterState = DefaultsKey<DeckState>("deckFilterState")
    static let deckFilterSort = DefaultsKey<DeckListSort>("deckFilterSort")
    
    // display/sort/scale for deckbuilder
    static let deckViewStyle = DefaultsKey<CardView>("deckViewStyle")
    static let deckViewSort = DefaultsKey<DeckSort>("deckSort")
    static let deckViewScale = DefaultsKey<Double>("deckViewScale")
    
    // deckbuilder card filer
    /// display mode for filter
    static let filterViewMode = DefaultsKey<CardFilterView>("filterViewMode")
    
    // display/sort/scale for browser
    static let browserViewStyle = DefaultsKey<CardView>("browserViewStyle")
    static let browserViewSort = DefaultsKey<BrowserSort>("browserSortType")
    static let browserViewScale = DefaultsKey<Double>("browserViewScale")
    
    // NetrunnerDB.com
    /// hostname
    static let nrdbHost = DefaultsKey<String>("nrdb_host")
    /// keep credentials locally in keychain?
    static let keepNrdbCredentials = DefaultsKey<Bool>("keepNrdbCredentials")
    // OAuth token stuff
    static let nrdbAccessToken = DefaultsKey<String?>("nrdbAccessToken")
    static let nrdbRefreshToken = DefaultsKey<String?>("nrdbRefreshToken")
    static let nrdbTokenExpiry = DefaultsKey<Date?>("nrdbTokenExpiry")
    static let nrdbTokenTTL = DefaultsKey<Double>("nrdbTokenTTL")
    
    /// date of last background fetch
    static let lastBackgroundFetch = DefaultsKey<String>("lastBackgroundFetch")
    /// date of last OAuth token refresh
    static let lastRefresh = DefaultsKey<String>("lastRefresh")
    
    /// identity selection: show as table?
    static let identityTable = DefaultsKey<Bool>("identityTable")
    
    /// which MWL to use?
    static let defaultMWL = DefaultsKey<MWL>("mwlVersion")
    /// exclude rotated-out cards?
    static let rotationActive = DefaultsKey<Bool>("rotationActive")
    /// which rotation to use?
    static let rotationIndex = DefaultsKey<Rotation>("rotationIndex")
    /// convert core -> core2?
    static let convertCore = DefaultsKey<Bool>("convertCore")
    
    /// which packs to use in browser
    static let browserPacks = DefaultsKey<PackUsage>("browserPacks")
    /// which packs to use in deck builder
    static let deckbuilderPacks = DefaultsKey<PackUsage>("deckBuilderPacks")
    
    /// iphone browser hint shown
    static let browserHintShown = DefaultsKey<Bool>("browserHintShown")
}

// add type-safe registerDefault methods
extension UserDefaults {
    func registerDefault<T: RawRepresentable>(_ key: DefaultsKey<T>, _ value: T) {
        Defaults.register(defaults: [ key._key: value.rawValue ])
    }
    
    func registerDefault<T>(_ key: DefaultsKey<T>, _ value: T) {
        Defaults.register(defaults: [ key._key: value ])
    }
}

// add subscript methods for our enums and typed dictionaries
extension UserDefaults {
    subscript(key: DefaultsKey<PackUsage>) -> PackUsage {
        get { return unarchive(key) ?? .all }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<Filter>) -> Filter {
        get { return unarchive(key) ?? .all }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<DeckState>) -> DeckState {
        get { return unarchive(key) ?? .none }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<DeckSort>) -> DeckSort {
        get { return unarchive(key) ?? .byFactionType }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<DeckListSort>) -> DeckListSort {
        get { return unarchive(key) ?? .byName }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<BrowserSort>) -> BrowserSort {
        get { return unarchive(key) ?? .byType }
        set { archive(key, newValue) }
    }

    subscript(key: DefaultsKey<MWL>) -> MWL {
        get { return unarchive(key) ?? .none }
        set { archive(key, newValue) }
    }

    subscript(key: DefaultsKey<CardView>) -> CardView {
        get { return unarchive(key) ?? .largeTable }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<CardFilterView>) -> CardFilterView {
        get { return unarchive(key) ?? .list }
        set { archive(key, newValue) }
    }

    subscript(key: DefaultsKey<[String: String]?>) -> [String: String]? {
        get { return dictionary(forKey: key._key) as? [String: String] ?? [:] }
        set { set(key, newValue) }
    }
    
    subscript(key: DefaultsKey<[String: Date]?>) -> [String: Date]? {
        get { return dictionary(forKey: key._key) as? [String: Date] ?? [:] }
        set { set(key, newValue) }
    }
    
    subscript(key: DefaultsKey<Rotation>) -> Rotation {
        get { return unarchive(key) ?? ._2017 }
        set { archive(key, newValue) }
    }
}

struct IASKButtons {
    static let downloadDataNow = "downloadDataNow"
    static let downloadImagesNow = "downloadImagesNow"
    static let downloadMissingImages = "downloadMissingImagesNow"
    static let clearCache = "clearCache"
    static let clearImageCache = "clearImageCache"
    static let refreshAuthNow = "refreshAuthNow"
    static let testAPI = "test_api"
}
 
struct KeychainKeys {
    static let nrdbUsername = "nrdbUsername"
    static let nrdbPassword = "nrdbPassword"

    static let jnetUsername = "jnetUsername"
    static let jnetPassword = "jnetPassword"
}
