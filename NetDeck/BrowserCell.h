//
//  BrowserCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 08.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface BrowserCell : UITableViewCell

@property (nonatomic) Card* card;
@property IBOutlet UIButton* moreButton;

-(IBAction)moreClicked:(id)sender;

@end
