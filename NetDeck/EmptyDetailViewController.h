//
//  EmptyDetailViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"

@interface EmptyDetailViewController : UIViewController <SubstitutableDetailViewController>

@property IBOutlet UIView* emptyDataSetView;

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UILabel* textLabel;
@property IBOutlet UIButton* downloadButton;

@property IBOutlet UIActivityIndicatorView* spinner;

-(IBAction)downloadTapped:(id)sender;

@end
