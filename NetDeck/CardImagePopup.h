//
//  CardImagePopup.h
//  Net Deck
//
//  Created by Gereon Steffens on 11.01.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@class CardImageCell;

@interface CardImagePopup : UIViewController

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* copiesLabel;
@property IBOutlet UIStepper* copiesStepper;

@property CardImageCell* cell;

-(IBAction) copiesChanged:(id)sender;

+(CardImagePopup*) showForCard:(CardCounter*)card inDeck:(Deck*)deck fromRect:(CGRect)rect inView:(UIView*)vc direction:(UIPopoverArrowDirection)direction;
+(void) dismiss;

@end
