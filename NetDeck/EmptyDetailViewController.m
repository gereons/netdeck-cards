//
//  EmptyDetailViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "EmptyDetailViewController.h"

@implementation EmptyDetailViewController

-(void) viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    [super viewDidLoad];
}


#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
