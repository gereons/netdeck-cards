//
//  DeckManager.m
//  NRDB
//
//  Created by Gereon Steffens on 18.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckManager.h"
#import "Deck.h"
#import "SettingsKeys.h"

#define SAVE_DECK  @"deck_%d"

@implementation DeckManager

// save a new Deck, return the new filename
+(NSString*) saveDeck:(Deck*)deck
{
    NSString* savePath = [DeckManager pathForRole:deck.role];
    
    [DeckManager saveDeck:deck toPath:savePath];
    return savePath;
}

// save a Deck
+(void) saveDeck:(Deck*)deck toPath:(NSString*)filename
{
    // Set up the encoder and storage for the saved state data
    NSMutableData* savedData = [NSMutableData data];
    NSKeyedArchiver* encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:savedData];
    
    [encoder encodeObject:deck forKey:@"deck"];
    
    // Finish encoding and write to the file
    [encoder finishEncoding];
    
    BOOL saveOk = [savedData writeToFile:filename atomically:YES];
    if (!saveOk)
    {
        [DeckManager removeFile:filename];
    }
}

// load a Deck
+(Deck*) loadDeckFromPath:(NSString *)filename
{
    // Check to see if the saved state file exists and if so, load it
    NSMutableData* savedData = [NSData dataWithContentsOfFile:filename];
    if (savedData == nil)
    {
        // no saved data
        return nil;
    }
    
    // decode the saved state
    NSKeyedUnarchiver* decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:savedData];
    Deck* deck = [decoder decodeObjectForKey:@"deck"];
    deck.filename = filename;
    return deck;
}

+(NSString*) directoryForRole:(NRRole)role
{
    NSAssert(role != NRRoleNone, @"wrong role");
    
    NSString* roleDirectory = role == NRRoleRunner ? @"runnerDecks" : @"corpDecks";
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* directory = [documentsDirectory stringByAppendingPathComponent:roleDirectory];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return directory;
}

// get a new filename
+(NSString*) pathForRole:(NRRole)role
{
    NSString* directory = [DeckManager directoryForRole:role];
    NSString* filename = [NSString stringWithFormat:@"deck-%d.anr", [DeckManager nextFileId]];
    NSString* path = [directory stringByAppendingPathComponent:filename];
    
    // NSLog(@"path: %@", path);
    return path;
}

+(NSMutableArray*) decksForRole:(NRRole)role
{
    if (role == NRFactionNone)
    {
        NSMutableArray* Decks = [self readDecksForRole:NRRoleRunner];
        [Decks addObjectsFromArray:[self readDecksForRole:NRRoleCorp]];
        return Decks;
    }
    else
    {
        return [self readDecksForRole:role];
    }
}

+(NSMutableArray*) readDecksForRole:(NRRole)role
{
    NSString* directory = [DeckManager directoryForRole:role];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    
    NSMutableArray* decks = [NSMutableArray array];
    
    for (NSString* file in dirContents)
    {
        NSString* pathname = [directory stringByAppendingPathComponent:file];
        
        @try
        {
            Deck* deck = [DeckManager loadDeckFromPath:pathname];
            
            [decks addObject:deck];
        }
        @catch (NSException* ex)
        {
            NSLog(@"caught exception loading %@", pathname);
            NSLog(@"exception was: %@ %@", ex.name, ex.reason);
            
            #if RELEASE
            [DeckManager removeFile:pathname];
            #endif
        }
    }
    
    return decks;
}

+(void) removeAll
{
    NSArray* roles = @[ @(NRRoleRunner), @(NRRoleCorp) ];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSError* error = nil;
    
    for (NSNumber* role in roles)
    {
        NSString* directory = [DeckManager directoryForRole:[role intValue]];
        NSArray *dirContents = [fileMgr contentsOfDirectoryAtPath:directory error:nil];

        for (NSString* file in dirContents)
        {
            NSString* pathname = [directory stringByAppendingPathComponent:file];
            
            // NSLog(@"removing %@", pathname);
            [fileMgr removeItemAtPath:pathname error:&error];
        }
    }
}

+(int) nextFileId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber* num = [defaults objectForKey:FILE_SEQ];
    int fileId = [num intValue];
    [defaults setObject:@(fileId+1) forKey:FILE_SEQ];
    [defaults synchronize];
    
    return fileId;
}


// remove save state file
+(void) removeFile:(NSString*)pathName
{
    // NSLog(@"removing %@", pathName);
    
    NSError* error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:pathName error:&error];
}


@end
