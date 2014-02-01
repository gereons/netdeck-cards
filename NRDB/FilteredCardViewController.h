//
//  FilteredCardViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 29.11.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DeckListViewController, Deck;

@interface FilteredCardViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NRRole role;

@property IBOutlet UIView *filterViewContainer;
@property IBOutlet UITableView* tableView;

@property (strong, nonatomic) DeckListViewController *deckListViewController;

-(id) initWithRole:(NRRole)role;
-(id) initWithRole:(NRRole)role andFile:(NSString*) filename;
-(id) initWithRole:(NRRole)role andDeck:(Deck*) deck;

@end
