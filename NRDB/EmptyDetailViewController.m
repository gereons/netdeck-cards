//
//  EmptyDetailViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 25.03.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "EmptyDetailViewController.h"

@implementation EmptyDetailViewController

-(void) viewDidLoad
{
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    [super viewDidLoad];
}


#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
