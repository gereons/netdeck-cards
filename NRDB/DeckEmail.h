//
//  DeckEmail.h
//  NRDB
//
//  Created by Gereon Steffens on 23.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@class Deck;

@interface DeckEmail : NSObject<MFMailComposeViewControllerDelegate>

+(BOOL) canSendMail;
+(void) emailDeck:(Deck*)deck fromViewController:(UIViewController*)viewController;

@end
