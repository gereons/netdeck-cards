//
//  EditDeckCell.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface EditDeckCell : UITableViewCell

@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* typeLabel;
@property IBOutlet UIStepper* stepper;
@property IBOutlet UIButton* idButton;

@end
