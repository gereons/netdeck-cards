
//
//  CardImageViewController.h
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@interface CardImageViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property IBOutlet UICollectionView* collectionView;

@property Card* selectedCard;

-(void) setCards:(NSArray<Card*>*)cards;
-(void) setCardCounters:(NSArray<CardCounter*>*)cardCounters;

@end
