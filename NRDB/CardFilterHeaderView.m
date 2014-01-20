//
//  CardFilterHeaderView.m
//  NRDB
//
//  Created by Gereon Steffens on 24.12.13.
//  Copyright (c) 2013 Gereon Steffens. All rights reserved.
//

#import "CardFilterHeaderView.h"

#import "CardType.h"
#import "CardSets.h"
#import "Faction.h"
#import "CardData.h"
#import "Notifications.h"
#import "CardFilterPopover.h"

enum { TYPE_BUTTON, FACTION_BUTTON, SET_BUTTON, SUBTYPE_BUTTON };

@interface CardFilterHeaderView()

@property NSString* searchText;
@property NRSearchScope scope;
@property BOOL sendNotifications;
@property NSString* selectedType;

@property NSMutableDictionary* selectedValues;

@end

@implementation CardFilterHeaderView

static NSArray* scopes;

+(void)initialize
{
    scopes = @[ @"all text", @"card name", @"card text" ];
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) awakeFromNib
{
    self.typeButton.tag = TYPE_BUTTON;
    self.setButton.tag = SET_BUTTON;
    self.factionButton.tag = FACTION_BUTTON;
    self.subtypeButton.tag = SUBTYPE_BUTTON;
    
    self.costSlider.maximumValue = 1+[CardData maxCost];
    self.muSlider.maximumValue = 1+[CardData maxMU];
    self.strengthSlider.maximumValue = 1+[CardData maxStrength];
    self.influenceSlider.maximumValue = 1+[CardData maxInfluence];
    self.apSlider.maximumValue = 1+[CardData maxAgendaPoints];
    
    self.searchText = @"";
    self.sendNotifications = YES;
    self.selectedType = kANY;
    
    self.selectedValues = [NSMutableDictionary dictionary];
}

-(void) setRole:(NRRole)role
{
    self->_role = role;
    
    self.muLabel.hidden = role == NRRoleCorp;
    self.muSlider.hidden = role == NRRoleCorp;
    self.apLabel.hidden = role == NRRoleRunner;
    self.apSlider.hidden = role == NRRoleRunner;
}

-(void) clearFilters
{
    self.sendNotifications = NO;
    
    self.scope = NRSearchAll;
    self.searchScope.selectedSegmentIndex = 0;
    self.searchField.text = @"";
    [self textFieldShouldClear:self.searchField];
    
    [self costValueChanged:nil];
    self.costSlider.value = 0;
    [self muValueChanged:nil];
    self.muSlider.value = 0;
    [self influenceValueChanged:nil];
    self.influenceSlider.value = 0;
    [self strengthValueChanged:nil];
    self.strengthSlider.value = 0;
    self.apSlider.value = 0;
    
    [self resetButton:TYPE_BUTTON];
    [self resetButton:SET_BUTTON];
    [self resetButton:FACTION_BUTTON];
    [self resetButton:SUBTYPE_BUTTON];
    self.selectedType = kANY;
    
    self.sendNotifications = YES;
    self.selectedValues = [NSMutableDictionary dictionary];
}

#pragma mark button callbacks

-(void) typeClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter type");
    TableData* data = [[TableData alloc] initWithValues:[CardType typesForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(TYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Type" singleSelection:YES selected:selected];
}

-(void) setClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter set");
    id selected = [self.selectedValues objectForKey:@(SET_BUTTON)];
    [CardFilterPopover showFromButton:sender inView:self entries:[CardSets allSetsForTableview] type:@"Set" singleSelection:NO selected:selected];
}

-(void) subtypeClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter subtype");
    TableData* data = [[TableData alloc] initWithValues:[CardType subtypesForRole:self.role andType:self.selectedType]];
    id selected = [self.selectedValues objectForKey:@(SUBTYPE_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Subtype" singleSelection:YES selected:selected];
}

-(void) factionClicked:(UIButton*)sender
{
    TF_CHECKPOINT(@"filter faction");
    TableData* data = [[TableData alloc] initWithValues:[Faction factionsForRole:self.role]];
    id selected = [self.selectedValues objectForKey:@(FACTION_BUTTON)];
    
    [CardFilterPopover showFromButton:sender inView:self entries:data type:@"Faction" singleSelection:NO selected:selected];
}

-(void) filterCallback:(UIButton *)button value:(NSObject *)object
{
    NSString* value = [object isKindOfClass:[NSString class]] ? (NSString*)object : nil;
    NSSet* values = [object isKindOfClass:[NSSet class]] ? (NSSet*)object : nil;
    NSAssert(value != nil || values != nil, @"values");
    
    if (button.tag == TYPE_BUTTON)
    {
        NSAssert(value != nil, @"value must be non-nil");
        self.selectedType = value;
        [self resetButton:SUBTYPE_BUTTON];
    }
    [self.selectedValues setObject:value ? value : values forKey:@(button.tag)];
}

#pragma mark slider callbacks

-(void) strengthValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter strength");
    int value = round(sender.value);
    // NSLog(@"str: %f %d", sender.value, value);
    sender.value = value--;
    self.strengthLabel.text = [NSString stringWithFormat:@"Strength: %@", value == -1 ? @"All" : [@(value) stringValue]];
    [self postNotification:@"strength" value:@(value)];
}

-(void) muValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter mu");
    int value = round(sender.value);
    // NSLog(@"mu: %f %d", sender.value, value);
    sender.value = value--;
    self.muLabel.text = [NSString stringWithFormat:@"MU: %@", value == -1 ? @"All" : [@(value) stringValue]];
    [self postNotification:@"mu" value:@(value)];
}

-(void) costValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter cost");
    int value = round(sender.value);
    // NSLog(@"cost: %f %d", sender.value, value);
    sender.value = value--;
    self.costLabel.text = [NSString stringWithFormat:@"Cost: %@", value == -1 ? @"All" : [@(value) stringValue]];
    [self postNotification:@"card cost" value:@(value)];
}

-(void) influenceValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter influence");
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.influenceLabel.text = [NSString stringWithFormat:@"Influence: %@", value == -1 ? @"All" : [@(value) stringValue]];
    [self postNotification:@"influence" value:@(value)];
}

-(void) apValueChanged:(UISlider*)sender
{
    TF_CHECKPOINT(@"filter ap");
    int value = round(sender.value);
    // NSLog(@"inf: %f %d", sender.value, value);
    sender.value = value--;
    self.apLabel.text = [NSString stringWithFormat:@"AP: %@", value == -1 ? @"All" : [@(value) stringValue]];
    [self postNotification:@"agendaPoints" value:@(value)];
}

#pragma mark actionsheet callback

-(void) resetButton:(NSInteger)tag
{
    UIButton* btn;
    NSString* pfx;
    NSString* value = kANY;
    switch (tag)
    {
        case SET_BUTTON:
        {
            btn = self.setButton;
            pfx = @"Set";
            break;
        }
        case TYPE_BUTTON:
        {
            btn = self.typeButton;
            pfx = @"Type";
            // reset subtypes to "any"
            [self resetButton:SUBTYPE_BUTTON];
            break;
        }
        case SUBTYPE_BUTTON:
        {
            btn = self.subtypeButton;
            pfx = @"Subtype";
            break;
        }
        case FACTION_BUTTON:
        {
            btn = self.factionButton;
            pfx = @"Faction";
            break;
        }
    }
    
    [self postNotification:[pfx lowercaseString] value:value];
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", pfx, value] forState:UIControlStateNormal];
    NSAssert(btn != nil, @"no button");
}

#pragma mark text search

-(void) scopeValueChanged:(UISegmentedControl*)sender
{
    TF_CHECKPOINT(@"filter scope");
    self.scope = sender.selectedSegmentIndex;
    [self postNotification:scopes[self.scope] value:self.searchText];
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.searchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // NSLog(@"search: %d %@", self.scope, self.searchText);
    
    [self postNotification:scopes[self.scope] value:self.searchText];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.searchText = @"";
    
    [self postNotification:scopes[self.scope] value:self.searchText];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark notification

-(void) postNotification:(NSString*)type value:(id)value
{
    if (self.sendNotifications)
    {
        NSDictionary* userInfo = @{ @"type": type, @"value": value };
        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_FILTER object:self userInfo:userInfo];
    }
}

@end
