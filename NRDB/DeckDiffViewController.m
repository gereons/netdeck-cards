//
//  DeckDiffViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 13.07.14.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "DeckDiffViewController.h"
#import "Deck.h"

@interface DeckDiffViewController ()
@property Deck* deck1;
@property Deck* deck2;
@end

@implementation DeckDiffViewController

+(void) showForDecks:(Deck*)deck1 deck2:(Deck*)deck2 inViewController:(UIViewController*)vc
{
    DeckDiffViewController* ddvc = [[DeckDiffViewController alloc] initWithDecks:deck1 deck2:deck2];
    
    [vc presentViewController:ddvc animated:NO completion:nil];
}

- (id)initWithDecks:(Deck*)deck1 deck2:(Deck*)deck2
{
    TF_CHECKPOINT(@"deck diff");
    
    self = [super initWithNibName:@"DeckDiffViewController" bundle:nil];
    if (self)
    {
        self.deck1 = deck1;
        self.deck2 = deck2;
        
        self.deck1Name.text = deck1.name;
        self.deck2Name.text = deck2.name;
        
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) close:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) reverse:(id)sender
{
    NSLog(@"reverse");
}

#pragma mark table view

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"diffCell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"diffCell"];
    }
    
    return cell;
}

@end
