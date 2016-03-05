//
//  ImageCache.h
//  Net Deck
//
//  Created by Gereon Steffens on 16.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#define IMAGE_WIDTH     300
#define IMAGE_HEIGHT    418

@interface ImageCache : NSObject

typedef void (^CompletionBlock)(Card* card, UIImage* image, BOOL placeholder);
typedef void (^UpdateCompletionBlock)(BOOL ok);

+(ImageCache*) sharedInstance;

-(void) clearLastModifiedInfo;
-(void) clearCache;
-(void) getImageFor:(Card *)card completion:(CompletionBlock)completionBlock;
-(void) updateMissingImageFor:(Card*)card completion:(UpdateCompletionBlock)completionBlock;
-(void) updateImageFor:(Card*)card completion:(UpdateCompletionBlock)completionBlock;
-(BOOL) imageAvailableFor:(Card*)card;

+(UIImage*) trashIcon;
+(UIImage*) strengthIcon;
+(UIImage*) creditIcon;
+(UIImage*) muIcon;
+(UIImage*) apIcon;
+(UIImage*) linkIcon;
+(UIImage*) cardIcon;
+(UIImage*) difficultyIcon;
+(UIImage*) influenceIcon;

+(UIImage*) placeholderFor:(NSInteger)role; // actually NRRole
+(UIImage*) hexTile;

+(UIImage*) croppedImage:(UIImage*)img forCard:(Card*)card;

@end
