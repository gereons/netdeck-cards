//
//  BrowserFilterViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 02.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserFilterViewController.h"
#import "BrowserResultViewController.h"

@interface BrowserFilterViewController ()

@property BrowserResultViewController* browser;
@property SubstitutableNavigationController* snc;

@end

@implementation BrowserFilterViewController

- (id) init
{
    if ((self = [super initWithNibName:@"BrowserFilterViewController" bundle:nil]))
    {
        self.browser = [[BrowserResultViewController alloc] initWithNibName:@"BrowserResultViewController" bundle:nil];
        
        self.snc = [[SubstitutableNavigationController alloc] initWithRootViewController:self.browser];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Do any additional setup after loading the view from its nib.
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Browser");
    
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearFiltersClicked:)];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self.snc;
}

#pragma mark button

-(void) clearFiltersClicked:(id)sender
{
}

@end
