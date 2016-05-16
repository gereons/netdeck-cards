//
//  EmptyDetailViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"

@interface EmptyDetailViewController : UIViewController <SubstitutableDetailViewController>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UILabel* textLabel;
@property IBOutlet UIButton* downloadButton;

-(IBAction)downloadTapped:(id)sender;

@end
