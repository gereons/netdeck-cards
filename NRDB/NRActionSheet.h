//
//  NRActionSheet.h
//  NRDB
//
//  Created by Gereon Steffens on 19.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

@interface NRActionSheet : UIActionSheet <UIActionSheetDelegate>

typedef void (^NRActionSheetBlock)(NSInteger buttonIndex);

- (void) showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated action:(NRActionSheetBlock)action;
- (void) showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated action:(NRActionSheetBlock)action;

@end
