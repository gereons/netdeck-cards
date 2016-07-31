//
//  SettingsKeys.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc class SettingsKeys: NSObject {
    static let LAST_MOD_CACHE      = "lastModified"
    static let NEXT_CHECK          = "nextCheck"
    static let UNAVAILABLE_IMAGES  = "unavailableImages"
    static let UNAVAIL_IMG_DATE    = "unavailableImagesDate"
    
    static let NEXT_UPDATE_CHECK   = "nextUpdateCheck"
    
    static let FILE_SEQ            = "fileSequence"
    static let LAST_START_VERSION  = "lastStartVersion"
    
    static let LAST_DOWNLOAD       = "lastDownload"
    static let NEXT_DOWNLOAD       = "nextDownload"
    static let DOWNLOAD_DATA_NOW   = "downloadDataNow"
    static let DOWNLOAD_IMG_NOW    = "downloadImagesNow"
    static let DOWNLOAD_MISSING_IMG = "downloadMissingImagesNow"
    static let UPDATE_INTERVAL     = "updateInterval"
    static let CLEAR_CACHE         = "clearCache"
    static let LANGUAGE            = "language"
    
    static let NUM_CORES           = "number_coresets"
    static let USE_DRAFT           = "use_draft"
    static let USE_DATA_DESTINY    = "use_dad"
    
    static let USE_DROPBOX         = "useDropbox"
    
    static let AUTO_SAVE           = "autoSave"
    static let AUTO_SAVE_DB        = "autoSaveDropbox"
    static let AUTO_HISTORY        = "autoHistory"
    
    static let CREATE_DECK_ACTIVE  = "createDeckActive"
    
    static let CLIP_CHANGE_COUNT   = "clipChangeCount"
    
    static let SHOW_ALL_FILTERS    = "showAllFilters"
    static let FILTER_VIEW_MODE    = "filterViewMode"
    
    static let DECK_FILTER_TYPE    = "deckFilterType"
    static let DECK_FILTER_STATE   = "deckFilterState"
    static let DECK_FILTER_SORT    = "deckFilterSort"
    
    static let DECK_VIEW_STYLE     = "deckViewStyle"
    static let DECK_VIEW_SORT      = "deckSort"
    static let DECK_VIEW_SCALE     = "deckViewScale"
    
    static let BROWSER_VIEW_SCALE  = "browserViewScale"
    static let BROWSER_VIEW_STYLE  = "browserViewStyle"
    static let BROWSER_SORT_TYPE   = "browserSortType"
    
    static let NRDB_HOST           = "nrdb_host"
    static let TEST_API            = "test_api"
    
    static let USE_NRDB            = "useNrdb"
    static let NRDB_ACCESS_TOKEN   = "nrdbAccessToken"
    static let NRDB_REFRESH_TOKEN  = "nrdbRefreshToken"
    static let NRDB_TOKEN_EXPIRY   = "nrdbTokenExpiry"
    static let NRDB_TOKEN_TTL      = "nrdbTokenTTL"
    static let NRDB_AUTOSAVE       = "nrdbAutoSave"
    static let REFRESH_AUTH_NOW    = "refreshAuthNow"
    static let LAST_BG_FETCH       = "lastBackgroundFetch"
    static let LAST_REFRESH        = "lastRefresh"
    
    static let KEEP_NRDB_CREDENTIALS = "keepNrdbCredentials"
    
    static let NRDB_USERNAME       = "nrdbUsername"
    static let NRDB_PASSWORD       = "nrdbPassword"

    static let USE_JNET            = "useJnet"
    static let JNET_USERNAME       = "jnetUsername"
    static let JNET_PASSWORD       = "jnetPassword"

    static let IDENTITY_TABLE      = "identityTable"
    
    static let MWL_VERSION         = "mwlVersion"
    
    static let BROWSER_PACKS       = "browserPacks"
    static let DECKBUILDER_PACKS   = "deckBuilderPacks"
}
