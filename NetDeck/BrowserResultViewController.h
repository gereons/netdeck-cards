//
//  BrowserResultViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "DetailViewManager.h"
#import "BrowserCollectionView.h"

@interface BrowserResultViewController : UIViewController <SubstitutableDetailViewController, UITabBarControllerDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property IBOutlet UITableView* tableView;
@property IBOutlet BrowserCollectionView* collectionView;

-(void)updateDisplay:(CardList*)cardList;

+(void) showPopupForCard:(Card*)card inView:(UIView*)view fromRect:(CGRect)rect;

@end
