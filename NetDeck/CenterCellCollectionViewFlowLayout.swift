//
//  CenterCellCollectionViewFlowLayout.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

class CenterCellCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        guard let collectionView = self.collectionView else {
            return proposedContentOffset
        }
                
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalCenter = proposedContentOffset.x + (collectionView.bounds.size.width / 2.0)
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0.0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
        
        guard let layoutAttributes = self.layoutAttributesForElements(in: targetRect) else {
            return proposedContentOffset
        }
        
        for attr in layoutAttributes {
            if attr.representedElementCategory == .cell {
                let itemHorizontalCenter = attr.center.x
                if abs(itemHorizontalCenter - horizontalCenter) < abs(offsetAdjustment) {
                    offsetAdjustment = itemHorizontalCenter - horizontalCenter
                }
            }
        }
        
        let minContentOffset = -collectionView.contentInset.left
        let maxContentOffset = minContentOffset + collectionView.contentSize.width - self.itemSize.width
        let snapStep = self.itemSize.width + self.minimumLineSpacing
        let velX = velocity.x
        
        var nextOffset = proposedContentOffset.x + offsetAdjustment
        var contentOffset = CGPoint.zero
        repeat {
            contentOffset.x = nextOffset
            let deltaX = contentOffset.x - collectionView.contentOffset.x
            
            if deltaX == 0.0 || velX == 0.0 || (velX > 0.0 && deltaX > 0.0) || (velX < 0.0 && deltaX < 0.0) {
                break
            }
            
            if velX > 0.0 {
                nextOffset += snapStep
            } else if velX < 0.0 {
                nextOffset -= snapStep
            }
        } while nextOffset >= minContentOffset && nextOffset <= maxContentOffset
        
        return contentOffset
    }
    
}
