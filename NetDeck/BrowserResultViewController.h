//
//  BrowserResultViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 03.08.14.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

@interface BrowserResultViewController : UIViewController <UITabBarControllerDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property IBOutlet UITableView* tableView;
@property IBOutlet UICollectionView* collectionView;

-(void)updateDisplay:(CardList*)cardList;

+(void) showPopupForCard:(Card*)card inView:(UIView*)view fromRect:(CGRect)rect;

@end
