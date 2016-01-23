//
//  EditDeckCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface EditDeckCell : UITableViewCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* typeLabel;
@property IBOutlet UIStepper* stepper;
@property IBOutlet UIButton* idButton;
@property IBOutlet UILabel* influenceLabel;
@property IBOutlet UILabel* mwlLabel;

@end
