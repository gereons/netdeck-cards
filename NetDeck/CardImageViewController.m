//
//  CardImageViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 10.08.15.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import <SVProgressHUD.h>

#import "CardImageViewController.h"
#import "CardImageViewCell.h"
#import "Deck.h"
#import "ImageCache.h"
#import "SettingsKeys.h"

@interface CardImageViewController ()

@property NSMutableArray* cardsArray;
@property NSMutableArray* countsArray;

@property BOOL initialScrollDone;

@end

@implementation CardImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = l10n(@"Cards");
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardImageViewCell" bundle:nil] forCellWithReuseIdentifier:@"cardCell"];
    
    if (self.parentViewController.view.frame.size.height == 480)
    {
        // iphone 4s
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        
        UISwipeGestureRecognizer* swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popNavigation:)];
        swipe.direction = UISwipeGestureRecognizerDirectionUp;
        
        [self.collectionView addGestureRecognizer:swipe];
        
        NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
        NSInteger hints = [settings integerForKey:IPHONE4_SWIPE_HINT];
        if (hints < 2)
        {
            [SVProgressHUD showInfoWithStatus:l10n(@"Swipe up to go back") maskType:SVProgressHUDMaskTypeBlack];
            [settings setInteger:hints+1 forKey:IPHONE4_SWIPE_HINT];
        }
    }
}

-(void)popNavigation:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void) setCards:(NSArray *)cards
{
    self.cardsArray = [NSMutableArray arrayWithArray:cards];
    self.countsArray = nil;
}

-(void) setCardCounters:(NSArray *)cardCounters
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
    
    Card* card = self.cardsArray[indexPath.row];
    
    if (self.countsArray == nil)
    {
        [cell setCard:card];
    }
    else
    {
        NSNumber* count = self.countsArray[indexPath.row];
        [cell setCard:card andCount:count.integerValue];
    }
    return cell;
}

@end
