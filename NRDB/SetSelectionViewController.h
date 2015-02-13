//
//  SetSelectionViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 13.02.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetSelectionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;

@end
