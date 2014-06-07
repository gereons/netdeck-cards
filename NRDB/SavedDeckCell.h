//
//  SavedDeckCell.h
//  NRDB
//
//  Created by Gereon Steffens on 18.05.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SavedDeckCell: UITableViewCell

@property UIButton* button;
@property UILabel* nameLabel;
@property UILabel* summaryLabel;

- (SavedDeckCell*) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@end