//
//  CSViewController.h
//  pixem
//
//  Created by Jon Como on 9/5/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import <MessageUI/MessageUI.h>
#import "CSCell.h"

#import "Social/Social.h"

@interface CSViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
    UIColor *drawColor;
    __weak IBOutlet UIView *drawView;
    
    NSTimer *drawDelay;
    NSTimer *liveTimer;
    NSTimer *gravityTimer;
    NSTimer *fillTimer;
    BOOL currentlyFilling;
    
    BOOL currentlyDrawing;
    
    UIView *cursorView;
    
    //Gravity
    CMMotionManager *motionManager;
    
    NSMutableArray *gridList;
    NSMutableArray *lastState;
    NSMutableArray *cellsFilling;
    UIColor *allowedToFillColor;
    
    __weak IBOutlet UIView *colorView;
    
    UIImage *savedImage;
    
    BOOL sampling;
    
    __weak IBOutlet UIImageView *backgroundImage;
    
    //Buttons
    __weak IBOutlet UIButton *liveButton;
    __weak IBOutlet UIButton *clearButton;
    __weak IBOutlet UIButton *saveButton;
    __weak IBOutlet UIButton *pickButton;
    
    __weak IBOutlet UIView *controlView;
    
    __weak IBOutlet UILabel *colorLabel;
    __weak IBOutlet UIView *livingView;
    __weak IBOutlet UILabel *livingLabel;
    
    //Constraints
    __weak IBOutlet NSLayoutConstraint *controlHeight;
    __weak IBOutlet NSLayoutConstraint *colorHeight;
}

- (IBAction)sampleColor:(id)sender;

- (IBAction)setBlack:(id)sender;
- (IBAction)setWhite:(id)sender;

- (IBAction)saveImage:(id)sender;
- (IBAction)clearImage:(id)sender;
- (IBAction)liveToggle:(id)sender;

@end