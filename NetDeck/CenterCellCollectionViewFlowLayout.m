//
//  CenterCellCollectionViewFlowLayout.m
//  NetDeck
//
//  Created by Gereon Steffens on 04.11.15.
//  Copyright © 2015 Gereon Steffens. All rights reserved.
//

#import "CenterCellCollectionViewFlowLayout.h"

@implementation CenterCellCollectionViewFlowLayout

- (CGPoint) targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (self.collectionView.bounds.size.width / 2.0);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
    NSArray* array = [self layoutAttributesForElementsInRect:targetRect];
    for (UICollectionViewLayoutAttributes *layoutAttributes in array)
    {
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            CGFloat itemHorizontalCenter = layoutAttributes.center.x;
            if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment))
            {
                offsetAdjustment = itemHorizontalCenter - horizontalCenter;
            }
        }
    }
    
    CGFloat nextOffset = proposedContentOffset.x + offsetAdjustment;
    
    do {
        proposedContentOffset.x = nextOffset;
        CGFloat deltaX = proposedContentOffset.x - self.collectionView.contentOffset.x;
        CGFloat velX = velocity.x;
        
        if (deltaX == 0.0 || velX == 0 || (velX > 0.0 && deltaX > 0.0) || (velX < 0.0 && deltaX < 0.0))
        {
            break;
        }
        
        if (velocity.x > 0.0)
        {
            nextOffset += [self snapStep];
        }
        else if(velocity.x < 0.0)
        {
            nextOffset -= [self snapStep];
        }
    } while ([self isValidOffset:nextOffset]);
    
    proposedContentOffset.y = 0.0;
    
    return proposedContentOffset;
}

- (BOOL)isValidOffset:(CGFloat)offset
{
    return (offset >= [self minContentOffset] && offset <= [self maxContentOffset]);
}

- (CGFloat)minContentOffset
{
    return -self.collectionView.contentInset.left;
}

- (CGFloat)maxContentOffset
{
    return [self minContentOffset] + self.collectionView.contentSize.width - self.itemSize.width;
}

- (CGFloat)snapStep
{
    return self.itemSize.width + self.minimumLineSpacing;
}

#if 0
-(CGPoint) targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGRect cvBounds = self.collectionView.bounds;
    CGFloat halfWidth = cvBounds.size.width / 2.0;
    CGFloat proposedContentOffsetCenterX = proposedContentOffset.x + halfWidth;
    
    NSLog(@"velocity=%@ propOffset=%@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(proposedContentOffset));
    
    NSMutableArray* attributesForVisibleCells;
    
    if (velocity.x > 2) {
        CGPoint proposedCenter = proposedContentOffset;
        proposedCenter.x += halfWidth;
        NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:proposedCenter];
        if (indexPath) {
            attributesForVisibleCells = [NSMutableArray array];
            [attributesForVisibleCells addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
        }
    }
    
    if (!attributesForVisibleCells) {
        attributesForVisibleCells = [self layoutAttributesForElementsInRect:cvBounds].mutableCopy;
    }
    
    if (attributesForVisibleCells.count > 0) {
        UICollectionViewLayoutAttributes* candidateAttrs;
        for (UICollectionViewLayoutAttributes* attrs in attributesForVisibleCells) {
            if (attrs.representedElementCategory != UICollectionElementCategoryCell) {
                continue;
            }
        
            if (candidateAttrs != nil) {
                CGFloat a = attrs.center.x - proposedContentOffsetCenterX;
                CGFloat b = candidateAttrs.center.x - proposedContentOffsetCenterX;
                
                NSLog(@"%g %g", a, b);
                
                if (fabs(a) < fabs(b)) {
                    candidateAttrs = attrs;
                }
            }
            else {
                candidateAttrs = attrs;
                continue;
            }
        }
        return CGPointMake(round(candidateAttrs.center.x - halfWidth), proposedContentOffset.y);
    }
    
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
}
#endif

@end
