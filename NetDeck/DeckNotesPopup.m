//
//  DeckNotesPopup.m
//  Net Deck
//
//  Created by Gereon Steffens on 01.06.14.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "DeckNotesPopup.h"
#import "SettingsKeys.h"
#import "Notifications.h"

@interface DeckNotesPopup ()

@property Deck* deck;

@end

@implementation DeckNotesPopup

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc
{
    DeckNotesPopup* dnp = [[DeckNotesPopup alloc] initWithDeck:deck];
    
    [vc presentViewController:dnp animated:NO completion:nil];
    dnp.preferredContentSize = CGSizeMake(540, 380);
}

- (id)initWithDeck:(Deck*)deck
{
    self = [super initWithNibName:@"DeckNotesPopup" bundle:nil];
    if (self)
    {
        self.deck = deck;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.cancelButton setTitle:l10n(@"Cancel") forState:UIControlStateNormal];
    [self.okButton setTitle:l10n(@"OK") forState:UIControlStateNormal];
    
    self.textView.text = self.deck.notes;
    self.titleLabel.text = self.deck.name;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // wtf? view does not move up if we do this synchronously...
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView becomeFirstResponder];
    });
}

-(void) okClicked:(id)sender
{
    self.deck.notes = self.textView.text;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTES_CHANGED object:nil];
    [self cancelClicked:sender];
}

-(void)cancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
