//
//  Notifications.h
//  Net Deck
//
//  Created by Gereon Steffens on 01.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#ifndef NETDECK_Notifications_h
#define NETDECK_Notifications_h

#define ADD_TOP_CARD    @"addTopCard"       // card filter: return pressed, add top card, no userInfo
#define SELECT_IDENTITY @"selectIdentity"   // identity selection, userInfo contains @"code"
#define DECK_CHANGED    @"deckChanged"      // change to current deck, e.g. count stepper, userInfo may contain @"initialLoad"=YES/NO
#define LOAD_DECK       @"loadDeck"         // load a deck from disk, userInfo contains @"filename" and @"role"
#define NEW_DECK        @"newDeck"          // create a new deck, userInfo contains @"role"
#define IMPORT_DECK     @"importDeck"       // import deck from clipboard, userInfo contains @"deck"
#define LOAD_CARDS      @"loadCards"        // card download from netrunnerdb.com, userInfo contains @"success" (BOOL)
#define DROPBOX_CHANGED @"dropboxChanged"   // dropbox link status changed, no userInfo
#define NOTES_CHANGED   @"notesChanged"     // notes for a deck changed, no userInfo
#define BROWSER_NEW     @"browserNew"       // new deck with card, userInfo contains @"code"
#define BROWSER_FIND    @"browserFind"      // find decks with card, userInfo contains @"code"
#define NAME_ALERT      @"nameAlert"        // name alert is about to appear, no userInfo

#endif
