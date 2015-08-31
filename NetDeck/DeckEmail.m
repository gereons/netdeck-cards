//
//  DeckEmail.m
//  Net Deck
//
//  Created by Gereon Steffens on 23.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "DeckEmail.h"
#import "DeckExport.h"
#import "Deck.h"

@interface DeckEmail()
@property UIViewController* viewController;
@end

@implementation DeckEmail

static DeckEmail* instance;

+(BOOL) canSendMail
{
    return [MFMailComposeViewController canSendMail];
}

+(DeckEmail*)sharedInstance
{
    if (!instance)
    {
        instance = [[DeckEmail alloc] init];
    }
    return instance;
}

+(void) emailDeck:(Deck *)deck fromViewController:(UIViewController *)viewController
{
    [[DeckEmail sharedInstance] sendAsEmail:deck fromViewController:viewController];
}

-(void) sendAsEmail:(Deck*)deck fromViewController:(UIViewController*)viewController
{
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    
    if (mailer)
    {
        mailer.mailComposeDelegate = self;
        NSString *emailBody = [DeckExport asPlaintextString:deck];
        [mailer setMessageBody:emailBody isHTML:NO];
        
        [mailer setSubject:deck.name];
        self.viewController = viewController;
        [self.viewController presentViewController:mailer animated:NO completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.viewController dismissViewControllerAnimated:NO completion:nil];
    self.viewController = nil;
}

@end
