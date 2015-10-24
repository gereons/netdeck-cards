//
//  DeckExport.m
//  Net Deck
//
//  Created by Gereon Steffens on 05.01.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <GRMustache.h>
#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>

#import "DeckExport.h"
#import "Deck.h"
#import "CardSets.h"
#import "GZip.h"

#define APP_NAME    "Net Deck"
#define APP_URL     "http://appstore.com/netdeck"

@implementation DeckExport

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
    
    [DeckExport writeToDropbox:content fileName:octgnName deckType:l10n(@"OCTGN Deck") autoSave:autoSave];
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
    
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (ISNULL(cc) || cc.card.type == NRCardTypeIdentity)
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
            
            NSUInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                [s appendString:[NSString stringWithFormat:@" %@\n", [DeckExport dots:influence]]];
            }
            else
            {
                [s appendString:@"\n"];
            }
            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %d)\n", numCards, deck.identity.minimumDecksize];
    [s appendFormat:@"%d/%d influence used\n", deck.influence, deck.identity.influenceLimit];
    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %d\n", deck.agendaPoints];
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
        dict[@"name"] = [deck.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
    [DeckExport writeToDropbox:s fileName:txtName deckType:l10n(@"Plain Text Deck") autoSave:NO];
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
    
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (ISNULL(cc) || cc.card.type == NRCardTypeIdentity)
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
            
            NSUInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                [s appendString:[NSString stringWithFormat:@" %@", [DeckExport dots:influence]]];
            }
            
            [s appendString:@"  \n"];
            
            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %d)  \n", numCards, deck.identity.minimumDecksize];
    [s appendFormat:@"%d/%d influence used  \n", deck.influence, deck.identity.influenceLimit];
    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %d  \n", deck.agendaPoints];
    }
    [s appendFormat:@"Cards up to %@\n", [CardSets mostRecentSetUsedInDeck:deck]];
    
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
    [DeckExport writeToDropbox:s fileName:mdName deckType:l10n(@"Markdown Deck") autoSave:NO];
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
    
    int numCards = 0;
    for (int i=0; i<sections.count; ++i)
    {
        NSArray* cards = cardsArray[i];
        CardCounter* cc = cards[0];
        if (ISNULL(cc) || cc.card.type == NRCardTypeIdentity)
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
            
            NSUInteger influence = [deck influenceFor:cc];
            if (influence > 0)
            {
                NSString* color = [NSString stringWithFormat:@"%lx", (unsigned long)cc.card.factionHexColor];
                [s appendString:[NSString stringWithFormat:@" [color=#%@]%@[/color]\n", color, [DeckExport dots:influence]]];
            }
            else
            {
                [s appendString:@"\n"];
            }
            numCards += cc.count;
        }
    }
    
    [s appendFormat:@"\n"];
    [s appendFormat:@"Cards in deck: %d (min %d)\n", numCards, deck.identity.minimumDecksize];
    [s appendFormat:@"%d/%d influence used\n", deck.influence, deck.identity.influenceLimit];
    if (deck.identity.role == NRRoleCorp)
    {
        [s appendFormat:@"Agenda Points: %d\n", deck.agendaPoints];
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
    [DeckExport writeToDropbox:s fileName:bbcName deckType:l10n(@"BBCode Deck") autoSave:NO];
}

+(NSString*) dots:(NSUInteger)count
{
    NSMutableString* s = [NSMutableString stringWithCapacity:count+5];
    for (int i=0; i<count; ++i)
    {
        [s appendString:@"·"];
        if ((i+1)%5 == 0 && i<count-1)
        {
            [s appendString:@" "];
        }
    }
    return s;
}

+(void) writeToDropbox:(NSString*)content fileName:(NSString*)filename deckType:(NSString*)deckType autoSave:(BOOL)autoSave
{
    BOOL writeOk = NO;
    @try
    {
        NSError* error;
        DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
        DBPath* path = [[DBPath root] childPath:filename];
        
        DBFile* textFile;
        if (path)
        {
            if ([filesystem fileInfoForPath:path error:&error] != nil)
            {
                textFile = [filesystem openFile:path error:&error];
            }
            else
            {
                textFile = [filesystem createFile:path error:&error];
            }
            writeOk = [textFile writeString:content error:&error];
            [textFile close];
        }
    }
    @catch (DBException* dbEx)
    {}
    
    if (autoSave)
    {
        return;
    }
    
    if (writeOk)
    {
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:l10n(@"%@ exported"), deckType]];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:l10n(@"Error exporting %@"), deckType]];
    }
}


@end
