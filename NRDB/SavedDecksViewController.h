//
//  SavedDecksViewController.h
//  X-Wing Squads
//
//  Created by Gereon Steffens on 22.03.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"


@interface SavedDecksViewController : UIViewController <SubstitutableDetailViewController, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem* editButton;

@property (nonatomic, strong) IBOutlet UITableView* tableView;

-(id) initWithRole:(NRRole)role;


@end
