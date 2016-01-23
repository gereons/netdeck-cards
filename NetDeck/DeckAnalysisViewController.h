//
//  DeckAnalysisViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.02.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface DeckAnalysisViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UILabel* titleLabel;
@property IBOutlet UITableView* tableView;
@property IBOutlet UIButton* okButton;

-(IBAction)done:(id)sender;

+(void) showForDeck:(Deck*)deck inViewController:(UIViewController*)vc;

@end
