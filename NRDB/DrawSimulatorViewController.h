//
//  DrawSimulatorViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 15.02.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Deck;
@interface DrawSimulatorViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UITableView* tableView;
@property IBOutlet UILabel* drawnLabel;

-(IBAction)done:(id)sender;
-(IBAction)clear:(id)sender;
-(IBAction)draw:(id)sender;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;
@end
