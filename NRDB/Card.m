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
#import "NSString+stripHTML.h"
#import <DTCoreText.h>

@interface Card()

@property NSAttributedString* attributedText;

@property (readwrite) BOOL isCore;

@end

@implementation Card

static NSDictionary* roleCodes;
static NSArray* max1InDeck;
static NSArray* specialIds;
static NSArray* draftIds;
static NSArray* multiIce;
static NSDictionary* coreTextOptions;
static NSDictionary* factionColors;
static NSDictionary* cropValues;
static BOOL isRetina;

+(void) initialize
{
    max1InDeck = @[ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT,
                    UTOPIA_SHARD, UTOPIA_FRAGMENT,
                    HADES_SHARD, HADES_FRAGMENT,
                    EDEN_SHARD, EDEN_FRAGMENT ];

    multiIce = @[ RAINBOW ];
    
    roleCodes = @{ @"Runner": @(NRRoleRunner), @"Corp": @(NRRoleCorp) };
    
    coreTextOptions = @{
                     DTUseiOS6Attributes: @(YES),
                     DTDefaultFontFamily: @"Helvetica",
                     DTDefaultFontSize: @(13)
    };
    
    isRetina = [UIScreen mainScreen].scale == 2.0;
   
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

-(Card*) altCard
{
    return [CardManager altCardFor:self.code];
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

#define JSON_INT(key, attr)          do { NSString*tmp = [json objectForKey:attr]; c->_##key = tmp ? [tmp intValue] : -1; } while (0)
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

+(Card*) cardFromJson:(NSDictionary*)json
{
    Card* c = [Card new];
    
    BOOL isNrdb = [json objectForKey:@"type_code"] != nil;
    
    JSON_STR(code, @"code");
    JSON_STR(name, @"title");
    c->_name = [c->_name stringByReplacingHTMLEntities];
    
    JSON_STR(text, @"text");
    c->_text = [c->_text stringByReplacingHTMLEntities];
    
    JSON_STR(flavor, @"flavor");
    JSON_STR(factionStr, @"faction");
    c->_faction = [Faction faction:c.factionStr];
    NSAssert(c.faction != NRFactionNone, @"no faction for %@", c.code);
    
    JSON_STR(roleStr, @"side");
    NSNumber* rc = [roleCodes objectForKey:c.roleStr];
    c->_role = rc ? rc.integerValue : NRRoleNone;
    NSAssert(c.role != NRRoleNone, @"no role for %@", c.code);

    JSON_STR(typeStr, @"type");
    c->_type = [CardType type:c.typeStr];
    NSAssert(c.type != NRCardTypeNone, @"no type for %@ (%@)", c.code, c.typeStr);
    
    JSON_STR(setName, @"set");
    if (isNrdb)
    {
        JSON_STR(setName, @"setname");
        NSString* setCode = [json objectForKey:@"set_code"];
        [CardSets registerNrdbCode:setCode andName:c->_setName];
        c->_setCode = setCode;
        if (c->_setCode == nil)
        {
            c->_setCode = UNKNOWN_SET_CODE;
        }

        if ([c->_setName isEqualToString:@"Core Set"])
        {
            c->_setName = @"Core";
        }
    }
    else
    {
        NSString* setCode = [json objectForKey:@"setcode"];
        c->_setCode = [CardSets setCodeForCgdbCode:setCode];
    }
    
    if ([[Card draftIds] containsObject:c->_code])
    {
        c->_setCode = DRAFT_SET_CODE;
        c->_setName = DRAFT_SET;
    }
    
    c->_isCore = [c.setName.lowercaseString isEqualToString:CORE_SET];
    
    JSON_STR(subtype, @"subtype");
    if (c.subtype.length == 0)
    {
        c->_subtype = nil;
    }
    if (c.subtype)
    {
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
        if (isNrdb)
        {
            JSON_INT(minimumDecksize, @"minimumdecksize");
        }
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
    if (isNrdb)
    {
        NSString* host = [[NSUserDefaults standardUserDefaults] objectForKey:NRDB_HOST];
        c->_imageSrc = [NSString stringWithFormat:@"http://%@%@", host, c->_imageSrc];
    }
    
    JSON_INT(maxPerDeck, @"maxperdeck");
    if (isNrdb)
    {
        c->_maxPerDeck = 3;
        NSNumber* limited = [json objectForKey:@"limited"];
        if (limited && limited.boolValue)
        {
            c->_maxPerDeck = 1;
        }
    }
    if ([max1InDeck containsObject:c.code] || c.type == NRCardTypeIdentity)
    {
        c->_maxPerDeck = 1;
    }
    
    return c;
}

-(BOOL) isValid
{
    return self.code.length > 0 && self.name.length > 0 && self.faction != NRFactionNone && self.role != NRRoleNone;
}

#pragma mark draft ids

+(NSArray*) draftIds
{
    Card* masque = [Card new];
    masque->_role = NRRoleRunner;
    masque->_code = THE_MASQUE;
    masque->_name = @"Masque";
    masque->_type = NRCardTypeIdentity;
    masque->_typeStr = @"Identity";
    masque->_faction = NRFactionNeutral;
    masque->_factionStr = @"Neutral";
    masque->_minimumDecksize = 30;
    masque->_influenceLimit = -1;
    masque->_setCode = DRAFT_SET_CODE;
    masque->_setName = DRAFT_SET;
    
    Card* shadow = [Card new];
    shadow->_role = NRRoleCorp;
    shadow->_code = THE_SHADOW;
    shadow->_name = @"Shadow";
    shadow->_type = NRCardTypeIdentity;
    shadow->_typeStr = @"Identity";
    shadow->_faction = NRFactionNeutral;
    shadow->_factionStr = @"Neutral";
    shadow->_minimumDecksize = 30;
    shadow->_influenceLimit = -1;
    shadow->_setCode = DRAFT_SET_CODE;
    shadow->_setName = DRAFT_SET;
    
    return @[masque, shadow];
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