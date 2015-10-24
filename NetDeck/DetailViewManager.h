//
//  DetailViewManager.h
//  Net Deck
//
//  Created by Gereon Steffens on 15.03.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

/*
 SubstitutableDetailViewController defines the protocol that detail view controllers must adopt.
 The protocol specifies a property for the bar button item controlling the navigation pane.
 */
@protocol SubstitutableDetailViewController

@end

@interface DetailViewManager : NSObject <UISplitViewControllerDelegate>

// Things for IB
// The split view this class will be managing.
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

// The presently displayed detail view controller.  This is modified by the various 
// view controllers in the navigation pane of the split view controller.
@property (nonatomic, assign) IBOutlet UIViewController<SubstitutableDetailViewController> *detailViewController;

@end

@interface SubstitutableNavigationController: UINavigationController<SubstitutableDetailViewController>
@end
