//
//  CSCell.m
//  pixem
//
//  Created by Jon Como on 9/5/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import "CSCell.h"

@implementation CSCell

@synthesize north, south, east, west, northEast, northWest, southEast, southWest, hasMoved;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = NO;
        hasMoved = NO;
    }
    return self;
}

-(UIColor *)colorOfRandomNeighbor
{
    return [self randomNeighbor].backgroundColor;
}

-(CSCell *)randomNeighbor
{
    NSArray *liveNeighbors = [self arrayOfLiveNeighbors];
    CSCell *cell = (CSCell *)[liveNeighbors objectAtIndex:arc4random()%[liveNeighbors count]];
    return cell;
}

-(NSArray *)arrayOfLiveNeighbors
{
    NSMutableArray *liveNeighbors = [[NSMutableArray alloc] initWithCapacity:8];
    
    if (self.north && self.north.backgroundColor != [UIColor blackColor] && self.north.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.north];
    if (self.south && self.south.backgroundColor != [UIColor blackColor] && self.south.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.south];
    if (self.east && self.east.backgroundColor != [UIColor blackColor] && self.east.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.east];
    if (self.west && self.west.backgroundColor != [UIColor blackColor] && self.west.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.west];
    
    if (self.northEast && self.northEast.backgroundColor != [UIColor blackColor] && self.northEast.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.northEast];
    if (self.northWest && self.northWest.backgroundColor != [UIColor blackColor] && self.northWest.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.northWest];
    if (self.southEast && self.southEast.backgroundColor != [UIColor blackColor] && self.southEast.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.southEast];
    if (self.southWest && self.southWest.backgroundColor != [UIColor blackColor] && self.southWest.backgroundColor != [UIColor clearColor]) [liveNeighbors addObject:self.southWest];
    
    return liveNeighbors;
}

-(NSArray *)arrayOfCardinalNeighbors
{
    NSMutableArray *cardinalNeighbors = [[NSMutableArray alloc] initWithCapacity:8];
    
    if (north) [cardinalNeighbors addObject:north];
    if (south) [cardinalNeighbors addObject:south];
    if (east) [cardinalNeighbors addObject:east];
    if (west) [cardinalNeighbors addObject:west];
    
    return cardinalNeighbors;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
