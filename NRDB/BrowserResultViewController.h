//
//  BrowserResultViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DetailViewManager.h"

@class Card, CardList;

@interface BrowserResultViewController : UIViewController <SubstitutableDetailViewController, UITabBarControllerDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate>

@property IBOutlet UITableView* tableView;
@property IBOutlet UICollectionView* collectionView;

-(void)updateDisplay:(CardList*)cardList;

+(void) showPopupForCard:(Card*)card inView:(UIView*)view fromRect:(CGRect)rect;

@end
