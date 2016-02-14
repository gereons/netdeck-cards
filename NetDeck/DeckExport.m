//
//  DeckExport.m
//  Net Deck
//
//  Created by Gereon Steffens on 05.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import GRMustache;
@import SVProgressHUD;

#import "DeckExport.h"
#import "GZip.h"

#define APP_NAME    "Net Deck"
#define APP_URL     "http://appstore.com/netdeck"

@implementation yDeckExport

+(void) asOctgn:(Deck*)deck autoSave:(BOOL)autoSave
{
    [GRMustache preventNSUndefinedKeyExceptionAttack];
    
    NSError* error;
    GRMustacheTemplate* template = [GRMustacheTemplate templateFromResource:@"OCTGN" bundle:nil error:&error];
    
    NSMutableDictionary* objects = [NSMutableDictionary dictionary];
    objects[@"identity"] = deck.identity;
    objects[@"cards"] = deck.cards;
    if (deck.notes)
    {
        objects[@"notes"] = deck.notes;
    }
    
    NSString* octgnName = [NSString stringWithFormat:@"%@.o8d", deck.name];
    NSString* content = [template renderObject:objects error:&error];
    
    [yDeckExport writeToDropbox:content fileName:octgnName deckType:l10n(@"OCTGN Deck") autoSave:autoSave];
}

+(NSString*) asPlaintextString:(Deck *)deck
{
    TableData* data = [deck dataForTableView:NRDeckSortType];
    NSArray* cardsArray = data.values;
    NSArray* sections = data.sections;
    
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    [s appendString:[NSString stringWithFormat:@"%@\n\n", deck.name]];
    if (deck.identity)
    {
        [s appendString:[NSString stringWithFormat:@"%@ (%@)\n", deck.identity.name, deck.identity.setName]];
    }
    
    BOOL useMWL = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NAPD_MWL];
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (cc.isNull || cc.card.type == NRCardTypeIdentity)
        {
            continue;
        }
        
        int cnt = 0;
        for (int j=0; j<cards.count; ++j) { CardCounter* cc = cards[j]; cnt += cc.count; }
        [s appendString:[NSString stringWithFormat:@"\n%@ (%d)\n", sections[i], cnt]];
        for (int j=0; j<cards.count; ++j)
        {
            CardCounter* cc = cards[j];
            [s appendString:[NSString stringWithFormat:@"%lux %@ (%@)", (unsigned long)cc.count, cc.card.name, cc.card.setName]];
            
            NSInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                [s appendString:[NSString stringWithFormat:@" %@", [DeckExport dots:influence]]];
            }
            if (useMWL && cc.card.isMostWanted) {
                [s appendString:@" (MWL)"];
            }
            
            [s appendString:@"\n"];
            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %ld)\n", numCards, (long)deck.identity.minimumDecksize];
    if (useMWL) {
        [s appendFormat:@"%ld/%ld (%ld-%ld) influence used\n", (long)deck.influence, (long)deck.influenceLimit, (long)deck.identity.influenceLimit, (long)deck.mwlPenalty];
        [s appendFormat:@"%ld cards from MWL\n", (long)deck.cardsFromMWL];
    } else {
        [s appendFormat:@"%ld/%ld influence used\n", (long)deck.influence, (long)deck.influenceLimit];
    }
    
    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %ld\n", (long)deck.agendaPoints];
    }
    [s appendFormat:@"Cards up to %@\n", [CardSets mostRecentSetUsedInDeck:deck]];
    
    [s appendString:@"\nDeck built with " APP_NAME " " APP_URL "\n"];
    
    if (deck.notes.length > 0)
    {
        [s appendString:@"\n"];
        [s appendString:deck.notes];
        [s appendString:@"\n"];
    }
    
    [s appendFormat:@"\n%@\n", [DeckExport localUrlForDeck:deck]];
    
    return s;
}

+(NSString*) localUrlForDeck:(Deck*)deck
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for (CardCounter* cc in deck.cards)
    {
        dict[cc.card.code] = @(cc.count);
    }
    if (deck.identity)
    {
        dict[deck.identity.code] = @(1);
    }
    if (deck.name.length > 0)
    {
        dict[@"name"] = [deck.name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    }
    
    NSMutableArray* keys = [dict allKeys].mutableCopy;
    [keys sortUsingComparator:^NSComparisonResult(NSString* c1, NSString* c2) {
        return [c1 compare:c2];
    }];
    
    NSMutableString* url = [[NSMutableString alloc] init];
    NSString* sep = @"";
    for (NSString* code in keys)
    {
        id qty = dict[code];
        [url appendFormat:@"%@%@=%@", sep, code, qty];
        sep = @"&";
    }
    
    NSData* compressed = [GZip gzipDeflate:[url dataUsingEncoding:NSUTF8StringEncoding]];
    NSString* base64url = [compressed base64EncodedStringWithOptions:0];
    NSCharacterSet* pathCharset = NSCharacterSet.URLPathAllowedCharacterSet;
    
    return [NSString stringWithFormat:@"netdeck://load/%@", [base64url stringByAddingPercentEncodingWithAllowedCharacters:pathCharset]];
}


+(void) asPlaintext:(Deck*)deck
{
    NSString* s = [DeckExport asPlaintextString:deck];
    NSString* txtName = [NSString stringWithFormat:@"%@.txt", deck.name];
    [yDeckExport writeToDropbox:s fileName:txtName deckType:l10n(@"Plain Text Deck") autoSave:NO];
}

+(NSString*) asMarkdownString:(Deck*)deck
{
    TableData* data = [deck dataForTableView:NRDeckSortType];
    NSArray* cardsArray = data.values;
    NSArray* sections = data.sections;
    
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    [s appendString:[NSString stringWithFormat:@"# %@\n\n", deck.name]];
    if (deck.identity)
    {
        [s appendString:[NSString stringWithFormat:@"%@ _(%@)_\n", deck.identity.name, deck.identity.setName]];
    }
    
    BOOL useMWL = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NAPD_MWL];
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (cc.isNull || cc.card.type == NRCardTypeIdentity)
        {
            continue;
        }
        
        int cnt = 0;
        for (int j=0; j<cards.count; ++j) { CardCounter* cc = cards[j]; cnt += cc.count; }
        [s appendString:[NSString stringWithFormat:@"\n## %@ (%d)\n", sections[i], cnt]];
        for (int j=0; j<cards.count; ++j)
        {
            CardCounter* cc = cards[j];
            [s appendString:[NSString stringWithFormat:@"%lux %@ _(%@)_", (unsigned long)cc.count, cc.card.name, cc.card.setName]];
            
            NSInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                [s appendString:[NSString stringWithFormat:@" %@", [DeckExport dots:influence]]];
            }
            if (useMWL && cc.card.isMostWanted) {
                [s appendString:@" (MWL)"];
            }
            
            [s appendString:@"  \n"];
            
            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %ld)  \n", numCards, (long)deck.identity.minimumDecksize];
    if (useMWL) {
        [s appendFormat:@"%ld/%ld (%ld-%ld) influence used  \n", (long)deck.influence, (long)deck.influenceLimit, (long)deck.identity.influenceLimit, (long)deck.mwlPenalty];
        [s appendFormat:@"%ld cards from MWL  \n", (long)deck.cardsFromMWL];
    } else {
        [s appendFormat:@"%ld/%ld influence used  \n", (long)deck.influence, (long)deck.influenceLimit];
    }

    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %ld  \n", (long)deck.agendaPoints];
    }
    [s appendFormat:@"Cards up to %@  \n", [CardSets mostRecentSetUsedInDeck:deck]];
    
    [s appendString:@"\nDeck built with [" APP_NAME "](" APP_URL ").\n"];
    
    if (deck.notes.length > 0)
    {
        [s appendString:@"\n"];
        [s appendString:deck.notes];
        [s appendString:@"\n"];
    }
    
    return s;
}

+(void) asMarkdown:(Deck*)deck
{
    NSString* s = [DeckExport asMarkdownString:deck];
    NSString* mdName = [NSString stringWithFormat:@"%@.md", deck.name];
    [yDeckExport writeToDropbox:s fileName:mdName deckType:l10n(@"Markdown Deck") autoSave:NO];
}

+(NSString*) asBBCodeString:(Deck*)deck
{
    TableData* data = [deck dataForTableView:NRDeckSortType];
    NSArray* cardsArray = data.values;
    NSArray* sections = data.sections;
    
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    [s appendString:[NSString stringWithFormat:@"[b]%@[/b]\n\n", deck.name]];
    if (deck.identity)
    {
        [s appendString:[NSString stringWithFormat:@"%@ (%@)\n", deck.identity.name, deck.identity.setName]];
    }
    
    BOOL useMWL = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_NAPD_MWL];
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (cc.isNull || cc.card.type == NRCardTypeIdentity)
        {
            continue;
        }
        
        int cnt = 0;
        for (int j=0; j<cards.count; ++j) { CardCounter* cc = cards[j]; cnt += cc.count; }
        [s appendString:[NSString stringWithFormat:@"\n[b]%@[/b] (%d)\n", sections[i], cnt]];
        for (int j=0; j<cards.count; ++j)
        {
            CardCounter* cc = cards[j];
            [s appendString:[NSString stringWithFormat:@"%lux %@ [i](%@)[/i]", (unsigned long)cc.count, cc.card.name, cc.card.setName]];
            
            NSInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                NSString* color = [NSString stringWithFormat:@"%lx", (unsigned long)cc.card.factionHexColor];
                [s appendString:[NSString stringWithFormat:@" [color=#%@]%@[/color]", color, [DeckExport dots:influence]]];
            }
            
            if (useMWL && cc.card.isMostWanted) {
                [s appendString:@" (MWL)"];
            }
            
            [s appendString:@"\n"];

            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %ld)\n", numCards, (long)deck.identity.minimumDecksize];
    if (useMWL) {
        [s appendFormat:@"%ld/%ld (%ld-%ld) influence used\n", (long)deck.influence, (long)deck.influenceLimit, (long)deck.identity.influenceLimit, (long)deck.mwlPenalty];
        [s appendFormat:@"%ld cards from MWL\n", (long)deck.cardsFromMWL];
    } else {
        [s appendFormat:@"%ld/%ld influence used\n", (long)deck.influence, (long)deck.influenceLimit];
    }

    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %ld\n", (long)deck.agendaPoints];
    }
    [s appendFormat:@"Cards up to %@\n", [CardSets mostRecentSetUsedInDeck:deck]];
    
    [s appendString:@"\nDeck built with [url=" APP_URL "]" APP_NAME "[/url].\n"];
    
    if (deck.notes.length > 0)
    {
        [s appendString:@"\n"];
        [s appendString:deck.notes];
        [s appendString:@"\n"];
    }
    
    return s;
}

+(void) asBBCode:(Deck*)deck
{
    NSString* s = [DeckExport asBBCodeString:deck];
    NSString* bbcName = [NSString stringWithFormat:@"%@.bbc", deck.name];
    [yDeckExport writeToDropbox:s fileName:bbcName deckType:l10n(@"BBCode Deck") autoSave:NO];
}

+(NSString*) dots:(NSUInteger)influence
{
    NSMutableString* s = [NSMutableString stringWithCapacity:influence+5];
    for (int i=0; i<influence; ++i)
    {
        [s appendString:@"·"];
        if ((i+1)%5 == 0 && i<influence-1)
        {
            [s appendString:@" "];
        }
    }
    return s;
}

+(void) writeToDropbox:(NSString*)content fileName:(NSString*)filename deckType:(NSString*)deckType autoSave:(BOOL)autoSave
{
    [NRDropbox saveFileToDropbox:content filename:filename completion:^(BOOL ok) {
        if (autoSave) {
            return;
        }
        if (ok) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:l10n(@"%@ exported"), deckType]];
        } else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:l10n(@"Error exporting %@"), deckType]];
        }
    }];
    
//    @try
//    {
//        NSError* error;
//        DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
//        DBPath* path = [[DBPath root] childPath:filename];
//        
//        DBFile* textFile;
//        if (path)
//        {
//            if ([filesystem fileInfoForPath:path error:&error] != nil)
//            {
//                textFile = [filesystem openFile:path error:&error];
//            }
//            else
//            {
//                textFile = [filesystem createFile:path error:&error];
//            }
//            writeOk = [textFile writeString:content error:&error];
//            [textFile close];
//        }
//    }
//    @catch (DBException* dbEx)
//    {}
}


@end
