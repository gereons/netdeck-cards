//
//  CardFilterPopover.h
//  NRDB
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TableData;
@class CardFilterHeaderView;

@interface CardFilterPopover : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;

+(void) showFromButton:(UIButton*)button inView:(CardFilterHeaderView*)view entries:(TableData*)entries type:(NSString*)type selected:(id)selected;

@end
