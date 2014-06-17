//
//  DeckExport.m
//  NRDB
//
//  Created by Gereon Steffens on 05.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <GRMustache.h>
#import <Dropbox/Dropbox.h>
#import <SVProgressHUD.h>

#import "DeckExport.h"
#import "Deck.h"
#import "CardSets.h"

#define APP_NAME    "Net Deck"
#define APP_URL     "http://appstore.com/netdeck"

@implementation DeckExport

+(void) asOctgn:(Deck*)deck autoSave:(BOOL)autoSave
{
    [GRMustache preventNSUndefinedKeyExceptionAttack];
    
    NSError* error;
    GRMustacheTemplate* template = [GRMustacheTemplate templateFromResource:@"OCTGN" bundle:nil error:&error];
    
    NSDictionary* objects = @{
        @"identity": deck.identity,
        @"cards": deck.cards
    };
    
    NSString* octgnName = [NSString stringWithFormat:@"%@.o8d", deck.name];
    NSString* content = [template renderObject:objects error:&error];
    
    if (deck.notes.length > 0)
    {
        NSString* notesName = [NSString stringWithFormat:@"%@_notes.txt", deck.name];
        
        [DeckExport writeToDropbox:deck.notes fileName:notesName deckType:nil autoSave:YES];
    }
    
    [DeckExport writeToDropbox:content fileName:octgnName deckType:l10n(@"OCTGN Deck") autoSave:autoSave];
}

+(NSString*) asPlaintextString:(Deck *)deck
{
    TableData* data = [deck dataForTableView];
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
    
    return s;
}

+(void) asPlaintext:(Deck*)deck
{
    NSString* s = [DeckExport asPlaintextString:deck];
    NSString* txtName = [NSString stringWithFormat:@"%@.txt", deck.name];
    [DeckExport writeToDropbox:s fileName:txtName deckType:l10n(@"Plain Text Deck") autoSave:NO];
}

+(NSString*) asMarkdownString:(Deck*)deck
{
    TableData* data = [deck dataForTableView];
    NSArray* cardsArray = data.values;
    NSArray* sections = data.sections;
    
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    [s appendString:[NSString stringWithFormat:@"# %@\n\n", deck.name]];
    if (deck.identity)
    {
        [s appendString:[NSString stringWithFormat:@"[%@](%@) _(%@)_\n", deck.identity.name, deck.identity.url, deck.identity.setName]];
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
            [s appendString:[NSString stringWithFormat:@"%lux [%@](%@) _(%@)_", (unsigned long)cc.count, cc.card.name, cc.card.url, cc.card.setName]];
            
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
    TableData* data = [deck dataForTableView];
    NSArray* cardsArray = data.values;
    NSArray* sections = data.sections;
    
    NSMutableString* s = [NSMutableString stringWithCapacity:1000];
    
    [s appendString:[NSString stringWithFormat:@"[b]%@[/b]\n\n", deck.name]];
    if (deck.identity)
    {
        [s appendString:[NSString stringWithFormat:@"[url=%@]%@[/url] (%@)\n", deck.identity.url, deck.identity.name, deck.identity.setName]];
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
            [s appendString:[NSString stringWithFormat:@"%lux [url=%@]%@[/url] [i](%@)[/i]", (unsigned long)cc.count, cc.card.url, cc.card.name, cc.card.setName]];
            
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
    NSError* error;
    DBFilesystem* filesystem = [DBFilesystem sharedFilesystem];
    DBPath* path = [[DBPath root] childPath:filename];
    
    DBFile* textFile;
    if ([filesystem fileInfoForPath:path error:&error] != nil)
    {
        textFile = [filesystem openFile:path error:&error];
    }
    else
    {
        textFile = [filesystem createFile:path error:&error];
    }
    BOOL writeOk = [textFile writeString:content error:&error];
    [textFile close];
    
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
