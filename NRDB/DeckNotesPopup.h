//
//  DeckNotesPopup.h
//  NRDB
//
//  Created by Gereon Steffens on 01.06.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck;
@interface DeckNotesPopup : UIViewController

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UIButton* okButton;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UITextView* textView;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;

@end