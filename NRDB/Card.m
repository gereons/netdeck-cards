//
//  Card.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Card.h"
#import "CardSets.h"
#import "CardManager.h"
#import "CardType.h"
#import "Faction.h"
#import "SettingsKeys.h"
#import <DTCoreText.h>

@interface Card()

@property NSAttributedString* attributedText;

@property (readwrite) BOOL isCore;

@end

@implementation Card

static NSDictionary* roleCodes;
static NSArray* max1InDeck;
static NSMutableArray* multiIce;
static NSDictionary* coreTextOptions;
static NSDictionary* factionColors;
static NSDictionary* cropValues;

+(void) initialize
{
    max1InDeck = MAX_1_PER_DECK;

    multiIce = [NSMutableArray array];
    
    roleCodes = @{ @"runner": @(NRRoleRunner), @"corp": @(NRRoleCorp) };
    
    coreTextOptions = @{
                     DTUseiOS6Attributes: @(YES),
                     DTDefaultFontFamily: @"Helvetica",
                     DTDefaultFontSize: @(13)
    };
    
    factionColors = @{
                      @(NRFactionJinteki):      @(0x940c00),
                      @(NRFactionNBN):          @(0xd7a32d),
                      @(NRFactionWeyland):      @(0x2d7868),
                      @(NRFactionHaasBioroid):  @(0x6b2b8a),
                      @(NRFactionShaper):       @(0x6ab545),
                      @(NRFactionCriminal):     @(0x4f67b0),
                      @(NRFactionAnarch):       @(0xf47c28)
    };
    
    cropValues = @{
                   @(NRCardTypeAgenda): @15,
                   @(NRCardTypeAsset): @20,
                   @(NRCardTypeEvent): @10,
                   @(NRCardTypeIdentity): @12,
                   @(NRCardTypeOperation): @10,
                   @(NRCardTypeHardware): @18,
                   @(NRCardTypeIce): @209,
                   @(NRCardTypeProgram): @8,
                   @(NRCardTypeResource): @11,
                   @(NRCardTypeUpgrade): @22,
    };
}

+(Card*) cardByCode:(NSString *)code
{
    return [CardManager cardByCode:code];
}

-(NSAttributedString*) attributedText
{
    if (!self->_attributedText)
    {
        NSString *str = [self.text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        NSAttributedString* attrStr = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:coreTextOptions
                                                                   documentAttributes:nil];
        
        self->_attributedText = attrStr;
    }
    return self->_attributedText;
}

-(NSString*) octgnCode
{
    return [NSString stringWithFormat:@"bc0f047c-01b1-427f-a439-d451eda%@", self.code];
}

-(NSUInteger) factionHexColor
{
    NSNumber*n = factionColors[@(self.faction)];
    return [n unsignedIntegerValue];
}

-(UIColor*) factionColor
{
    NSUInteger rgb = [self factionHexColor];
    return UIColorFromRGB(rgb);
}

-(int) cropY
{
    NSNumber*n = cropValues[@(self.type)];
    return [n intValue];
}

-(NSInteger) owned
{
    if (self.isCore)
    {
        NSInteger cores = [[NSUserDefaults standardUserDefaults] integerForKey:NUM_CORES];
        return MIN(3, cores * self.quantity);
    }
    return 3;
}

-(NSString*) iceType
{
    NSAssert(self.type == NRCardTypeIce, @"not an ice");
    
    if ([multiIce containsObject:self.code])
    {
        return l10n(@"Multi");
    }
    
    NSString* type = [self.subtypes objectAtIndex:0];
    return type == nil ? l10n(@"ICE") : type;
}

-(NSString*) programType
{
    NSAssert(self.type == NRCardTypeProgram, @"not a program");
    
    NSString* type = [self.subtypes objectAtIndex:0];
    if ([type isEqualToString:[CardManager iceBreakerType]])
    {
        return type;
    }
    return self.typeStr;
}

#pragma mark from json

#define JSON_INT(key, attr)          do { NSString* tmp = [json objectForKey:attr]; c->_##key = tmp ? [tmp intValue] : -1; } while (0)
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

+(Card*) cardFromJson:(NSDictionary*)json
{
    Card* c = [Card new];
    
    JSON_STR(code, @"code");
    JSON_STR(name, @"title");
    c->_name = [c->_name stringByReplacingHTMLEntities];
    c->_name_en = c->_name;
    
    JSON_STR(text, @"text");
    c->_text = [c->_text stringByReplacingHTMLEntities];
    
    JSON_STR(flavor, @"flavor");
    JSON_STR(factionStr, @"faction");
    NSString* factionCode = [json objectForKey:@"faction_code"];
    c->_faction = [Faction faction:factionCode];
    NSAssert(c.faction != NRFactionNone, @"no faction for %@", c.code);
    // remove the "consortium" from weyland's name
    if (c.faction == NRFactionWeyland)
    {
        c->_factionStr = @"Weyland";
    }
    
    JSON_STR(roleStr, @"side");
    NSString* roleCode = [json objectForKey:@"side_code"];
    NSNumber* rc = [roleCodes objectForKey:roleCode.lowercaseString];
    c->_role = rc ? rc.integerValue : NRRoleNone;
    NSAssert(c.role != NRRoleNone, @"no role for %@", c.code);

    JSON_STR(typeStr, @"type");
    NSString* typeCode = [json objectForKey:@"type_code"];
    c->_type = [CardType type:typeCode];
    NSAssert(c.type != NRCardTypeNone, @"no type for %@ (%@)", c.code, c.typeStr);
    
    JSON_STR(setName, @"setname");
    JSON_STR(setCode, @"set_code");
    if (c->_setCode == nil)
    {
        c->_setCode = UNKNOWN_SET;
        c->_setName = UNKNOWN_SET;
    }

    c->_setNumber = [CardSets setNumForCode:c->_setCode];
        
    if ([DRAFT_IDS containsObject:c.code])
    {
        c->_setCode = DRAFT_SET_CODE;
        c->_setName = DRAFT_SET_NAME;
    }
    if ([SPECIAL_IDS containsObject:c.code])
    {
        c->_setCode = SPECIAL_SET_CODE;
        c->_setName = SPECIAL_SET_NAME;
    }
    
    c->_isCore = [c.setName caseInsensitiveCompare:CORE_SET_CODE] == NSOrderedSame;
    
    JSON_STR(subtype, @"subtype");
    if (c.subtype.length == 0)
    {
        c->_subtype = nil;
    }
    if (c.subtype)
    {
        c->_subtype = [c.subtype stringByReplacingOccurrencesOfString:@"G-Mod" withString:@"G-mod"];
        c->_subtype = [c.subtype stringByReplacingOccurrencesOfString:@" – " withString:@" - "]; // fix dashes in german subtypes
        c->_subtypes = [c.subtype componentsSeparatedByString:@" - "];
    }
    
    JSON_INT(number, @"number");
    JSON_INT(quantity, @"quantity");
    c->_quantity = MIN(3, c->_quantity);
    JSON_BOOL(unique, @"uniqueness");
    
    if (c.type == NRCardTypeIdentity)
    {
        JSON_INT(influenceLimit, @"influencelimit");
        JSON_INT(minimumDecksize, @"mindecksize");
        JSON_INT(minimumDecksize, @"minimumdecksize");
        JSON_INT(baseLink, @"baselink");
    }
    else
    {
        c->_influenceLimit = -1;
        c->_minimumDecksize = -1;
        c->_baseLink = -1;
    }
    if (c.type == NRCardTypeAgenda)
    {
        JSON_INT(advancementCost, @"advancementcost");
        JSON_INT(agendaPoints, @"agendapoints");
    }
    else
    {
        c->_advancementCost = -1;
        c->_agendaPoints = -1;
    }
    JSON_INT(mu, @"memoryunits");
    JSON_INT(strength, @"strength");
    JSON_INT(cost, @"cost");
    JSON_INT(influence, @"factioncost");
    JSON_INT(trash, @"trash");
    
    JSON_STR(imageSrc, @"imagesrc");
    if (c->_imageSrc.length > 0)
    {
        NSString* host = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_HOST];
        c->_imageSrc = [NSString stringWithFormat:@"http://%@%@", host, c->_imageSrc];
    }
    
    if (c->_imageSrc == nil)
    {
        NSArray* images = [json objectForKey:@"images"];
        if ([images isKindOfClass:[NSArray class]] && images.count > 0)
        {
            NSDictionary* img = images[0];
            c->_imageSrc = [img objectForKey:@"src"];
        }
    }
    
    if (c->_imageSrc.length == 0)
    {
        c->_imageSrc = nil;
    }
    
    JSON_INT(maxPerDeck, @"maxperdeck");
    c->_maxPerDeck = 3;
    NSNumber* limited = [json objectForKey:@"limited"];
    if (limited && limited.boolValue)
    {
        c->_maxPerDeck = 1;
    }

    if ([max1InDeck containsObject:c.code] || c.type == NRCardTypeIdentity)
    {
        c->_maxPerDeck = 1;
    }
    
    if ([self isMultiIce:c])
    {
        [multiIce addObject:c.code];
    }
    
    JSON_STR(ancurLink, @"ancurLink");
    if (c.ancurLink.length == 0)
    {
        c->_ancurLink = nil;
    }
    
    return c;
}

+(BOOL) isMultiIce:(Card*)card
{
    BOOL en = [card.subtypes containsObject:@"Sentry"]
           && [card.subtypes containsObject:@"Barrier"]
           && [card.subtypes containsObject:@"Code Gate"];
    BOOL localized = [card.subtypes containsObject:l10n(@"Sentry")]
                  && [card.subtypes containsObject:l10n(@"Barrier")]
                  && [card.subtypes containsObject:l10n(@"Code Gate")];
    return en || localized;
}

-(BOOL) isValid
{
    return self.code.length > 0 && self.name.length > 0 && self.faction != NRFactionNone && self.role != NRRoleNone;
}

#pragma mark nsobject

-(BOOL) isEqual:(id)object
{
    Card* other = (Card*)object;
    return [self.code isEqualToString:other.code];
}

- (NSUInteger)hash
{
    return self.code.hash;
}

@end