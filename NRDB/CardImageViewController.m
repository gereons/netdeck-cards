//
//  CardImageViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "CardImageViewController.h"
#import "CardImageViewCell.h"
#import "Deck.h"
#import "ImageCache.h"

@interface CardImageViewController ()

@property NSArray* cards;
@property BOOL initialScrollDone;

@end

@implementation CardImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cards = [self.deck allCards];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardImageViewCell" bundle:nil] forCellWithReuseIdentifier:@"cardCell"];
}

- (void)viewDidLayoutSubviews
{
    // If we haven't done the initial scroll, do it once.
    if (!self.initialScrollDone)
    {
        self.initialScrollDone = YES;
        
        NSInteger row;
        for (row = 0; row<self.cards.count; ++row)
        {
            CardCounter* cc = self.cards[row];
            if ([cc.card isEqual:self.selectedCard])
            {
                break;
            }
        }
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}


#pragma mark - collection view

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.cards.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CardImageViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cardCell" forIndexPath:indexPath];
    
    CardCounter* cc = self.cards[indexPath.row];
    
    cell.card = cc.card;
    return cell;
}

@end
