//
//  DeckNotesPopup.h
//  Net Deck
//
//  Created by Gereon Steffens on 01.06.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface DeckNotesPopup : UIViewController

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UIButton* okButton;
@property IBOutlet UIButton* cancelButton;
@property IBOutlet UITextView* textView;

-(IBAction)okClicked:(id)sender;
-(IBAction)cancelClicked:(id)sender;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;

@end
