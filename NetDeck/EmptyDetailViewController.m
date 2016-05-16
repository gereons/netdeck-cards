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
    [super viewDidLoad];
    
    self.titleLabel.text = l10n(@"No Card Data");
    self.textLabel.text = l10n(@"To use this app, you must first download card data.");
    [self.downloadButton setTitle:l10n(@"Download") forState:UIControlStateNormal];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
}

-(void) downloadTapped:(id)sender {
    [DataDownload downloadCardData];
}

@end
