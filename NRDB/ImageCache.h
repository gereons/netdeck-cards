//
//  ImageCache.h
//  NRDB
//
//  Created by Gereon Steffens on 16.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;
@interface ImageCache : NSObject

typedef void (^CompletionBlock)(Card* card, UIImage* image, BOOL placeholder);
typedef void (^UpdateCompletionBlock)(BOOL ok);

+(ImageCache*) sharedInstance;

-(void) clearCache;
-(void) getImageFor:(Card *)card completion:(CompletionBlock)completionBlock;
-(void) updateMissingImageFor:(Card*)card completion:(UpdateCompletionBlock)completionBlock;
-(void) updateImageFor:(Card*)card completion:(UpdateCompletionBlock)completionBlock;

+(UIImage*) trashIcon;
+(UIImage*) strengthIcon;
+(UIImage*) creditIcon;
+(UIImage*) muIcon;
+(UIImage*) apIcon;
+(UIImage*) linkIcon;
+(UIImage*) cardIcon;
+(UIImage*) difficultyIcon;
+(UIImage*) influenceIcon;

+(UIImage*) altArtIcon:(BOOL)on;

+(UIImage*) placeholderFor:(NRRole)role;
+(UIImage*) hexTile;

+(UIImage*) croppedImage:(UIImage*)img forCard:(Card*)card;

@end
