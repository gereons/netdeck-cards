//
//  CGRectUtils.h
//  Net Deck
//
//  Created by Gereon Steffens on 28.04.12.
//  Copyright (c) 2012 Gereon Steffens. All rights reserved.
//

#ifndef NETDECK_CGRectUtils_h
#define NETDECK_CGRectUtils_h

#define CGRectSetPos(r, X, Y)   CGRectMake( X, Y, r.size.width, r.size.height )
#define CGRectSetX(r, X)        CGRectMake( X, r.origin.y, r.size.width, r.size.height )
#define CGRectSetY(r, Y)        CGRectMake( r.origin.x, Y, r.size.width, r.size.height )

#define CGRectSetSize(r, W, H)  CGRectMake( r.origin.x, r.origin.y, W, H )
#define CGRectSetWidth(r, W)    CGRectMake( r.origin.x, r.origin.y, W, r.size.height )
#define CGRectSetHeight(r, H)   CGRectMake( r.origin.x, r.origin.y, r.size.width, H )

#define CGRectAddX(r, X)         CGRectMake( r.origin.x + X, r.origin.y, r.size.width, r.size.height )
#define CGRectAddY(r, Y)         CGRectMake( r.origin.x, r.origin.y + Y, r.size.width, r.size.height )
#define CGRectAddWidth(r, W)     CGRectMake( r.origin.x, r.origin.y, r.size.width + W, r.size.height )
#define CGRectAddHeight(r, H)    CGRectMake( r.origin.x, r.origin.y, r.size.width, r.size.height + H )


#endif
