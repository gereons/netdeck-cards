//
//  CardFilterPopover.h
//  NRDB
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "FilterCallback.h"

@class TableData;
@class CardFilterViewController;

@interface CardFilterPopover : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;

+(void) showFromButton:(UIButton*)button inView:(UIViewController<FilterCallback>*)vc entries:(TableData*)entries type:(NSString*)type selected:(id)selected;

@end
