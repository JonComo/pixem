//
//  CSCell.h
//  pixem
//
//  Created by Jon Como on 9/5/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSCell;

@interface CSCell : UIView

@property (weak, nonatomic) CSCell *north;
@property (weak, nonatomic) CSCell *northEast;
@property (weak, nonatomic) CSCell *northWest;

@property (weak, nonatomic) CSCell *south;
@property (weak, nonatomic) CSCell *southEast;
@property (weak, nonatomic) CSCell *southWest;

@property (weak, nonatomic) CSCell *east;
@property (weak, nonatomic) CSCell *west;

@property BOOL hasMoved;

-(UIColor *)colorOfRandomNeighbor;
-(NSArray *)arrayOfLiveNeighbors;
-(NSArray *)arrayOfCardinalNeighbors;
-(CSCell *)randomNeighbor;

@end