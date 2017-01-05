//
//  CardFilterPopover.h
//  Net Deck
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

#import "FilterCallback.h"

@class CardFilterViewController;

@interface CardFilterPopover : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView* tableView;

+(void) showFromButton:(UIButton*)button inView:(UIViewController<FilterCallback>*)vc entries:(TableData*)entries type:(NSString*)type selected:(id)selected;

@end
