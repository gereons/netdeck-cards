//
//  ImportDecksViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 12.01.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportDecksViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, NSXMLParserDelegate>

@property IBOutlet UITableView* tableView;

@end
