//
//  CardEditorViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingTableView.h"

@interface CardEditorViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UIAlertViewDelegate>

@property (strong) IBOutlet TPKeyboardAvoidingTableView *tableView;

@end
