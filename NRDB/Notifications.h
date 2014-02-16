//
//  Notifications.h
//  NRDB
//
//  Created by Gereon Steffens on 01.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#ifndef NRDB_Notifications_h
#define NRDB_Notifications_h

#define UPDATE_FILTER   @"updateFilter"     // card filter, userInfo contains @"type" and @"value"
#define ADD_TOP_CARD    @"addTopCard"       // card filter: return pressed, add top card, no userInfo
#define SELECT_IDENTITY @"selectIdentity"   // identity selection, userInfo contains @"code"
#define DECK_CHANGED    @"deckChanged"      // change to current deck, e.g. count stepper, no userInfo
#define DECK_LOADED     @"deckLoaded"       // deck was loaded into editor, no userInfo
#define LOAD_DECK       @"loadDeck"         // load a deck from disk, userInfo contains @"filename" and @"role"
#define IMPORT_DECK     @"importDeck"       // import deck from clipboard, userInfo contains @"deck"
#define LOAD_CARDS      @"loadCards"        // card download from netrunnerdb.com, no userInfo
#define DROPBOX_CHANGED @"dropboxChanged"   // dropbox link status changed, no userInfo

#endif
