//
//  IphoneDrawSimulator.h
//  Net Deck
//
//  Created by Gereon Steffens on 23.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Deck;

@interface IphoneDrawSimulator : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UISegmentedControl* drawControl;
@property IBOutlet UILabel *oddsLabel;

-(IBAction)drawValueChanged:(id)sender;

@property Deck* deck;

@end
