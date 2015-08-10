//
//  CardImageViewController.h
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

@class Deck, Card;

@interface CardImageViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property IBOutlet UICollectionView* collectionView;

@property Deck* deck;
@property Card* selectedCard;

@end
