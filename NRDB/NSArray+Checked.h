//
//  NSArray+Checked.h
//  NRDB
//
//  Created by Gereon Steffens on 17.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@interface NSArray (Checked)

-(id) get:(NSUInteger)index;
-(id) get2d:(NSIndexPath*)indexPath;

@end
