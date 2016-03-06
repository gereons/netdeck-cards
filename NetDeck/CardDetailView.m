//
//  CardDetailView.m
//  Net Deck
//
//  Created by Gereon Steffens on 03.05.14.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

#import "CardDetailView.h"
#import "CardImageViewPopover.h"
#import "CardImageCell.h"
#import "BrowserImageCell.h"
#import "CardImageViewCell.h"

@implementation CardDetailView

+(void) setupDetailViewFromPopover:(CardImageViewPopover *)popover card:(Card*)card
{
    CardDetailView* cdv = [[CardDetailView alloc] init];
    
    cdv.card = card;
    cdv.detailView = popover.detailView;
    cdv.cardName = popover.cardName;
    cdv.cardType = popover.cardType;
    cdv.cardText = popover.cardText;
    
    cdv.icon1 = popover.icon1;
    cdv.icon2 = popover.icon2;
    cdv.icon3 = popover.icon3;
    
    cdv.label1 = popover.label1;
    cdv.label2 = popover.label2;
    cdv.label3 = popover.label3;
    
    [cdv setupDetailView];
}

+(void) setupDetailViewFromCell:(CardImageCell *)cell card:(Card*)card
{
    CardDetailView* cdv = [[CardDetailView alloc] init];
    
    cdv.card = card;
    cdv.detailView = cell.detailView;
    cdv.cardName = cell.cardName;
    cdv.cardType = cell.cardType;
    cdv.cardText = cell.cardText;
    
    cdv.icon1 = cell.icon1;
    cdv.icon2 = cell.icon2;
    cdv.icon3 = cell.icon3;
    
    cdv.label1 = cell.label1;
    cdv.label2 = cell.label2;
    cdv.label3 = cell.label3;
    
    [cdv setupDetailView];
}

+(void) setupDetailViewFromBrowser:(BrowserImageCell *)cell card:(Card*)card
{
    CardDetailView* cdv = [[CardDetailView alloc] init];
    
    cdv.card = card;
    cdv.detailView = cell.detailView;
    cdv.cardName = cell.cardName;
    cdv.cardType = cell.cardType;
    cdv.cardText = cell.cardText;
    
    cdv.icon1 = cell.icon1;
    cdv.icon2 = cell.icon2;
    cdv.icon3 = cell.icon3;
    
    cdv.label1 = cell.label1;
    cdv.label2 = cell.label2;
    cdv.label3 = cell.label3;
    
    [cdv setupDetailView];
}

+(void) setupDetailViewFromIphone:(CardImageViewCell *)cell card:(Card *)card
{
    CardDetailView* cdv = [[CardDetailView alloc] init];
    
    cdv.card = card;
    cdv.detailView = cell.detailView;
    cdv.cardName = cell.cardName;
    cdv.cardType = cell.cardType;
    cdv.cardText = cell.cardText;
    
    cdv.icon1 = cell.icon1;
    cdv.icon2 = cell.icon2;
    cdv.icon3 = cell.icon3;
    
    cdv.label1 = cell.label1;
    cdv.label2 = cell.label2;
    cdv.label3 = cell.label3;
    
    [cdv setupDetailView];
}

-(void) setupDetailView
{
    self.detailView.hidden = NO;
    self.detailView.backgroundColor = [UIColor colorWithWhite:1 alpha:.7];
    self.detailView.layer.cornerRadius = 10;
    self.detailView.layer.masksToBounds = YES;
    
    Card* card = self.card;
    
#if DEBUG
    self.cardName.text = [NSString stringWithFormat:@"%@ (%@)", card.name, card.code];
#else
    self.cardName.text = card.name;
#endif
    
    // hack: remove padding from the text view
    // see https://stackoverflow.com/questions/746670/how-to-lose-margin-padding-in-uitextview
    self.cardText.textContainer.lineFragmentPadding = 0;
    self.cardText.textContainerInset = UIEdgeInsetsZero;
    self.cardText.attributedText = card.attributedText;
    
    NSString* factionName = [Faction name:card.faction];
    NSString* typeName = [CardType name:card.type];
    NSString* subtype = card.subtype;
    if (subtype)
    {
        self.cardType.text = [NSString stringWithFormat:@"%@ · %@: %@", factionName, typeName, card.subtype];
    }
    else
    {
        self.cardType.text = [NSString stringWithFormat:@"%@ · %@", factionName, typeName];
    }
    
    // labels from top: cost/strength/mu
    switch (card.type)
    {
        case NRCardTypeIdentity:
            self.label1.text = [@(card.minimumDecksize) stringValue];
            self.icon1.image = [ImageCache cardIcon];
            if (card.influenceLimit == -1)
            {
                self.label2.text = @"∞";
            }
            else
            {
                self.label2.text = [@(card.influenceLimit) stringValue];
            }
            self.icon2.image = [ImageCache influenceIcon];
            if (card.role == NRRoleRunner)
            {
                self.label3.text = [NSString stringWithFormat:@"%ld", (long)card.baseLink];
                self.icon3.image = [ImageCache linkIcon];
            }
            else
            {
                self.label3.text = @"";
                self.icon3.image = nil;
            }
            break;
            
        case NRCardTypeProgram:
        case NRCardTypeResource:
        case NRCardTypeEvent:
        case NRCardTypeHardware:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%ld", (long)card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = card.strength != -1 ? [NSString stringWithFormat:@"%ld", (long)card.strength] : @"";
            self.icon2.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            self.label3.text = card.mu != -1 ? [NSString stringWithFormat:@"%ld", (long)card.mu] : @"";
            self.icon3.image = card.mu != -1 ? [ImageCache muIcon] : nil;
            break;
            
        case NRCardTypeIce:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%ld", (long)card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.strength != -1 ? [NSString stringWithFormat:@"%ld", (long)card.strength] : @"";
            self.icon3.image = card.strength != -1 ? [ImageCache strengthIcon] : nil;
            break;
            
        case NRCardTypeAgenda:
            self.label1.text = [NSString stringWithFormat:@"%ld", (long)card.advancementCost];
            self.icon1.image = [ImageCache difficultyIcon];
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = [NSString stringWithFormat:@"%ld", (long)card.agendaPoints];
            self.icon3.image = [ImageCache apIcon];
            break;
            
        case NRCardTypeAsset:
        case NRCardTypeOperation:
        case NRCardTypeUpgrade:
            self.label1.text = card.cost != -1 ? [NSString stringWithFormat:@"%ld", (long)card.cost] : @"";
            self.icon1.image = card.cost != -1 ? [ImageCache creditIcon] : nil;
            self.label2.text = @"";
            self.icon2.image = nil;
            self.label3.text = card.trash != -1 ? [NSString stringWithFormat:@"%ld", (long)card.trash] : @"";
            self.icon3.image = card.trash != -1 ? [ImageCache trashIcon] : nil;
            break;
            
        case NRCardTypeNone:
            NSAssert(NO, @"this can't happen");
            break;
    }
}

@end
