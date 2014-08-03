//
//  BrowserFilterViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 02.08.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "BrowserFilterViewController.h"

@interface BrowserFilterViewController ()

@end

@implementation BrowserFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Do any additional setup after loading the view from its nib.
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    topItem.title = l10n(@"Browser");
    
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearFiltersClicked:)];
}

#pragma mark button

-(void) clearFiltersClicked:(id)sender
{
}

@end
