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

typedef void (^SuccessCompletionBlock)(Card* card, UIImage* image);
typedef void (^ErrorCompletionBlock)(Card* card, NSInteger statusCode, UIImage* placeholderImage);

+(ImageCache*) sharedInstance;

-(void) clearCache;
-(void) getImageFor:(Card *)card success:(SuccessCompletionBlock)successBlock failure:(ErrorCompletionBlock)failureBlock;
-(void) getImageFor:(Card *)card success:(SuccessCompletionBlock)successBlock failure:(ErrorCompletionBlock)failureBlock forced:(BOOL)forced;

+(UIImage*) trashIcon;
+(UIImage*) strengthIcon;
+(UIImage*) creditIcon;
+(UIImage*) muIcon;
+(UIImage*) apIcon;
+(UIImage*) linkIcon;
+(UIImage*) cardIcon;
+(UIImage*) difficultyIcon;
+(UIImage*) influenceIcon;

@end
