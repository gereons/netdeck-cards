//
//  CardImageViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;

#import "CardImageViewController.h"
#import "CardImageViewCell.h"

@interface CardImageViewController ()

@property NSMutableArray<Card*>* cardsArray;
@property NSMutableArray<NSNumber*>* countsArray;

@property BOOL initialScrollDone;

@end

@implementation CardImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // self.title = l10n(@"Cards");
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardImageViewCell" bundle:nil] forCellWithReuseIdentifier:@"cardCell"];
    
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
}

-(BOOL) prefersStatusBarHidden
{
    return Device.isIphone4;
}

-(void) setCards:(NSArray<Card*>*)cards
{
    self.cardsArray = [NSMutableArray arrayWithArray:cards];
    self.countsArray = nil;
}

-(void) setCardCounters:(NSArray<CardCounter*>*)cardCounters
{
    self.cardsArray = [NSMutableArray array];
    self.countsArray = [NSMutableArray array];
    
    for (CardCounter* cc in cardCounters)
    {
        [self.cardsArray addObject:cc.card];
        [self.countsArray addObject:@(cc.count)];
    }
}

- (void)viewDidLayoutSubviews
{
    // If we haven't done the initial scroll, do it once.
    if (!self.initialScrollDone)
    {
        if (self.cardsArray.count == 1) {
            // force the insets so that the card is centered
            UIEdgeInsets oldInset = self.collectionView.contentInset;
            CGFloat frameWidth = self.collectionView.frame.size.width;
            UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
            CGFloat offset = (frameWidth - layout.itemSize.width - layout.minimumLineSpacing * 2.0) / 2.0;
            UIEdgeInsets newInset = UIEdgeInsetsMake(oldInset.top, offset, oldInset.bottom, offset);
            self.collectionView.contentInset = newInset;
        }
        
        self.initialScrollDone = YES;
        
        NSInteger row;
        for (row = 0; row<self.cardsArray.count; ++row)
        {
            Card* card = self.cardsArray[row];
            if ([card.code isEqual:self.selectedCard.code])
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
    return self.cardsArray.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CardImageViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cardCell" forIndexPath:indexPath];
    cell.showAsDifferences = self.showAsDifferences;
    
    Card* card = self.cardsArray[indexPath.row];
    
    if (self.countsArray == nil) {
        [cell setCard:card];
    } else {
        NSNumber* count = self.countsArray[indexPath.row];
        [cell setCard:card andCount:count.integerValue];
    }
    return cell;
}

@end
