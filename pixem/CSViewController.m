//
//  CSViewController.m
//  pixem
//
//  Created by Jon Como on 9/5/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import "CSViewController.h"

#define DOCS [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define FILEMANAGER [NSFileManager defaultManager]

@interface CSViewController ()

@end

@implementation CSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    doubleTap.delaysTouchesBegan = NO;
    doubleTap.delaysTouchesEnded = NO;
    currentlyFilling = NO;
    
    [self.view addGestureRecognizer:doubleTap];
    
    //Gravity
    motionManager = [[CMMotionManager alloc] init];
    
    drawColor = [UIColor clearColor];
    
    [self layoutGridInView:drawView withPixelSize:CGSizeMake(10, 10) color:[UIColor clearColor]];
    [self applyNeighborsForCellsInGrid];
    
    NSString *savePath = [NSString stringWithFormat:@"%@/pixem", DOCS];
    if ([FILEMANAGER fileExistsAtPath:savePath]) {
        NSLog(@"Restoring");
        //Extract data out of pixem file and apply it to the view
        [self restoreSavedDrawingInFile:savePath];
    }
    
    lastState = [self arrayOfColorsInPixem];
    
    [self setDrawColor:[UIColor purpleColor]];
    
    [self hideLiving:YES animated:NO title:@"living"];
    
    [self createCursor];
    
    currentlyDrawing = NO;
    
    sampling = NO;
    
    //Background image
    UIImage *transparentImage = [[UIImage imageNamed:@"pixels"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [backgroundImage setImage:transparentImage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view becomeFirstResponder];
    [super viewDidAppear:animated];
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventSubtypeMotionShake) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"want to undo?" message:nil delegate:self cancelButtonTitle:@"no" otherButtonTitles:@"yes", nil];
        [alert show];
    }
}

-(void)restoreSavedDrawingInFile:(NSString *)pathToFile
{
    NSData *loadedData = [NSData dataWithContentsOfFile:pathToFile];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:loadedData];
    NSMutableArray *colors = [unarchiver decodeObjectForKey:@"colors"];
    [unarchiver finishDecoding];
    
    [self restorePixemFromArray:colors];
}

-(void)restorePixemFromArray:(NSArray *)array
{
    for (int i = 0; i<array.count; i++) {
        UIView *subView = [drawView.subviews objectAtIndex:i];
        [subView setBackgroundColor:(UIColor *)[array objectAtIndex:i]];
    }
}

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
    NSLog(@"Foreground");
    [self.view becomeFirstResponder];
}

-(void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self savePixemToFile:[NSString stringWithFormat:@"%@/pixem", DOCS]];
}

-(void)savePixemToFile:(NSString *)pathToSave
{
    NSMutableArray *colors = [self arrayOfColorsInPixem];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:colors forKey:@"colors"];
    [archiver finishEncoding];
    
    [data writeToFile:pathToSave atomically:YES];
}

-(NSMutableArray *)arrayOfColorsInPixem
{
    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:drawView.subviews.count];
    for (UIView *subView in drawView.subviews) {
        [colors addObject:subView.backgroundColor];
    }
    return colors;
}

-(void)hideLiving:(BOOL)hide animated:(BOOL)animated title:(NSString *)title
{
    livingLabel.text = title;
    if(animated) [UIView beginAnimations:@"living" context:nil];
    if (hide) {
        livingView.alpha = 0;
    }else{
        livingView.alpha = 1;
    }
    if(animated) [UIView commitAnimations];
}

-(void)createCursor
{
    cursorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [cursorView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:cursorView];
    
    NSTimer *cursorBlink;
    cursorBlink = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(blinkCursor) userInfo:nil repeats:YES];
}

-(void)blinkCursor
{
    if (sampling) {
        if ([cursorView.backgroundColor isEqual:[UIColor whiteColor]]) {
            cursorView.backgroundColor = drawColor;
        }else{
            cursorView.backgroundColor = [UIColor whiteColor];
        }
    }else{
        if ([cursorView.backgroundColor isEqual:[UIColor whiteColor]]) {
            cursorView.backgroundColor = drawColor;
        }else{
            cursorView.backgroundColor = [UIColor whiteColor];
        }
    }
}

#pragma Touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *subTouch in touches){
        if (subTouch.view == colorView) {
            [UIView animateWithDuration:0.3 animations:^{
                colorHeight.constant = 120;
                controlHeight.constant = 170;
                [self.view layoutSubviews];
            }];
        }
    }
    
    CGPoint currentPosition = [[touches anyObject] locationInView:self.view];
    
    CGPoint offsetPosition = CGPointMake(currentPosition.x, currentPosition.y - 60);
    
    [UIView animateWithDuration:0.1 animations:^{
        cursorView.center = offsetPosition;
    }];
    
    //Wait 0.2 seconds before drawing to let user see where cursor is
    drawDelay = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(enableDrawing) userInfo:nil repeats:NO];
    
    if (!currentlyFilling) lastState = [self arrayOfColorsInPixem];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *subTouch in touches){
        if (subTouch.view == colorView) {
            
            CGPoint colorPosition = [subTouch locationInView:colorView];
            
            float saturation;
            float brightness;
            
            if (colorPosition.y < 60) {
                saturation = colorPosition.y/60;
                brightness = 1;
            }else{
                saturation = 1;
                brightness = (50 - (colorPosition.y - 60))/50;
            }
            
            [self setDrawColor:[UIColor colorWithHue:colorPosition.x*1.125/360.0 saturation:saturation brightness:brightness alpha:1]];
            return;
        }
    }
    
    UITouch *touch = [touches anyObject];
	CGPoint currentPosition = [touch locationInView:drawView];
    
    CGPoint offsetPosition = CGPointMake(currentPosition.x, currentPosition.y -= 60);
    
    cursorView.center = CGPointMake(offsetPosition.x, offsetPosition.y);
    
    if(sampling) {
        //Get color at point
        [self setDrawColor:[self cellNearPoint:offsetPosition].backgroundColor];
        NSLog(@"Neighbors: %@", [[self cellNearPoint:offsetPosition] arrayOfCardinalNeighbors]);
    }else if(currentlyDrawing){
        [self changeViewNearPoint:offsetPosition toColor:drawColor];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    currentlyDrawing = NO;
    [drawDelay invalidate];
    drawDelay = nil;
    
    if (sampling) {
        [self setSampling:NO];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        colorHeight.constant = 50;
        controlHeight.constant = 100;
        [self.view layoutSubviews];
    }];
}

#pragma filling methods

-(void)doubleTap:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"Filling");
    
    if (cellsFilling) {
        [self stopFilling];
        return;
    }
    
    [self startFilling];
}

-(void)startFilling
{
    allowedToFillColor = [self cellNearPoint:cursorView.center].backgroundColor;
    
    if ([drawColor isEqual:allowedToFillColor]) return; //Already filled
    
    fillTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(fillStep:) userInfo:nil repeats:YES];
    
    cellsFilling = nil;
    cellsFilling = [[NSMutableArray alloc] init];
    
    [self hideLiving:NO animated:YES title:@"filling"];
    currentlyFilling = YES;
}

-(void)stopFilling
{
    NSLog(@"Done filling");
    cellsFilling = nil;
    [fillTimer invalidate];
    fillTimer = nil;
    
    [self hideLiving:YES animated:YES title:@"filling"];
    currentlyFilling = NO;
}

-(void)fillStep:(NSTimer *)timer
{
    //Get color of currently hovered pixel
    if ([cellsFilling count] == 0) {
        //Get first cell and add it in to the array
        CSCell *fillStartCell = [self cellNearPoint:cursorView.center];
        [cellsFilling addObject:fillStartCell];
    }
    
    NSMutableArray *cellsThatGotFilled = [[NSMutableArray alloc] init];
    //Get neighbors of cell that we are near
    for (CSCell *cell in cellsFilling)
    {
        //Fill the neighbors with the first cell color
        NSArray *cardinalNeighbors = [cell arrayOfCardinalNeighbors];
        for (CSCell *neighbor in cardinalNeighbors)
        {
            if ([neighbor.backgroundColor isEqual:allowedToFillColor]) {
                neighbor.backgroundColor = drawColor;
                [cellsThatGotFilled addObject:neighbor];
            }
        }
    }
    
    if ([cellsThatGotFilled count] == 0) {
        [self stopFilling];
        return;
    }
    
    cellsFilling = cellsThatGotFilled;
}

#pragma CONWAYS RULES OF LIFE

/*
 Any live cell with fewer than two live neighbours dies, as if caused by under-population.
 Any live cell with two or three live neighbours lives on to the next generation.
 Any live cell with more than three live neighbours dies, as if by overcrowding.
 Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
*/

-(void)stepLife
{
    for (int i = 0; i<[drawView.subviews count]; i++) {
        //Cycle through all cells
        CSCell *workingCell = [drawView.subviews objectAtIndex:i];
        NSArray *liveNeighbors = [workingCell arrayOfLiveNeighbors];
        int aliveNeighbors = [liveNeighbors count];
        if (workingCell.backgroundColor != [UIColor clearColor] && workingCell.backgroundColor != [UIColor blackColor]) {
            //Cell is alive
            if (aliveNeighbors < 2 || aliveNeighbors > 3) {
                //Kill cell due to under population or over population
                float rand = (float)(arc4random()%4);
                float time = rand/10;
                [UIView animateWithDuration:time animations:^{
                    workingCell.backgroundColor = [UIColor clearColor];
                }];
            }
        }else if(workingCell.backgroundColor == [UIColor clearColor])
        {
            //Cell is dead
            if(aliveNeighbors == 3){
                //Come alive, due to reproduction, picking one of your neighbors colors!
                CSCell *randNeighbor = [liveNeighbors objectAtIndex:arc4random()%[liveNeighbors count]];
                float rand = (float)(arc4random()%4);
                float time = rand/10;
                [UIView animateWithDuration:time animations:^{
                    workingCell.backgroundColor = randNeighbor.backgroundColor;
                }];
            }
        }
    }
}

-(void)stepGravity
{
    //Gravity, analyze and figure out which direction its going
    
    float x = 0;
    float y = 0;
    
    if ([motionManager isAccelerometerAvailable]) {
        CMAccelerometerData *data;
        data = motionManager.accelerometerData;
        x = data.acceleration.x;
        y = data.acceleration.y;
    }
    
    for (CSCell *childCell in drawView.subviews) {
        childCell.hasMoved = NO;
    }
    
    if (arc4random()%2) {
        for (int i = 0; i<drawView.subviews.count-1; i++) {
            CSCell *workingCell = [drawView.subviews objectAtIndex:i];
            if (!workingCell.hasMoved && ![workingCell.backgroundColor isEqual:[UIColor clearColor]]){
                if (![workingCell.backgroundColor isEqual:[UIColor blackColor]]) {
                    if (x>0) {
                        if ([self probabilityFromFloat:x]) [self moveCell:workingCell toCell:workingCell.west];
                    }else {
                        if ([self probabilityFromFloat:-x]) [self moveCell:workingCell toCell:workingCell.east];
                    }
                    if (y>0) {
                        if ([self probabilityFromFloat:y]) [self moveCell:workingCell toCell:workingCell.north];
                    }else {
                        if ([self probabilityFromFloat:-y]) [self moveCell:workingCell toCell:workingCell.south];
                    }
                }
            }
        }
    }else{
        for (int i = drawView.subviews.count-1; i>0; i--) {
            CSCell *workingCell = [drawView.subviews objectAtIndex:i];
            if (!workingCell.hasMoved && ![workingCell.backgroundColor isEqual:[UIColor clearColor]]){
                if (![workingCell.backgroundColor isEqual:[UIColor blackColor]]) {
                    if (x>0) {
                        if ([self probabilityFromFloat:x]) [self moveCell:workingCell toCell:workingCell.west];
                    }else {
                        if ([self probabilityFromFloat:-x]) [self moveCell:workingCell toCell:workingCell.east];
                    }
                    if (y>0) {
                        if ([self probabilityFromFloat:y]) [self moveCell:workingCell toCell:workingCell.north];
                    }else {
                        if ([self probabilityFromFloat:-y]) [self moveCell:workingCell toCell:workingCell.south];
                    }
                }
            }
        }
    }
    
}

-(void)moveCell:(CSCell *)cell toCell:(CSCell *)childCell
{
    if ([childCell.backgroundColor isEqual:[UIColor clearColor]]) {
        childCell.backgroundColor = cell.backgroundColor;
        cell.backgroundColor = [UIColor clearColor];
        childCell.hasMoved = YES;
    }
}

-(BOOL)probabilityFromFloat:(float)skew
{
    BOOL returnBool = NO;
    
    if ( skew * 1000 > arc4random()%1000) returnBool = YES;
    
    return returnBool;
}

#pragma Drawing methods

-(void)enableDrawing
{
    currentlyDrawing = YES;
}

-(void)changeViewNearPoint:(CGPoint)point toColor:(UIColor *)color
{
    NSArray *views = drawView.subviews;
    int distance = 1000;
    
    CSCell *closestView;
    for (int i = 0; i<[views count]; i++) {
        CSCell *subView = (CSCell *)[views objectAtIndex:i];
        int checkDist = [self distanceBetweenPointA:subView.center pointB:point];
        if (checkDist < distance) {
            distance = checkDist;
            closestView = subView;
        }
    }
    
    [closestView setBackgroundColor:color];
}

-(CSCell *)cellNearPoint:(CGPoint)point
{
    NSArray *views = drawView.subviews;
    int distance = 1000;
    
    CSCell *closestView;
    for (CSCell *subView in views) {
        int checkDist = [self distanceBetweenPointA:subView.center pointB:point];
        if (checkDist < distance) {
            distance = checkDist;
            closestView = subView;
        }
    }
    
    return closestView;
}

-(float)distanceBetweenPointA:(CGPoint)pointA pointB:(CGPoint)pointB
{
    float returnDist;
    
    float dx = pointA.x - pointB.x;
    float dy = pointA.y - pointB.y;
    returnDist = sqrtf(dx*dx + dy*dy);
    
    return returnDist;
}

-(void)layoutGridInView:(UIView *)view withPixelSize:(CGSize)size color:(UIColor *)color
{
    int numPixelsHigh = 29;
    int numPixelsWide = 32;
    
    gridList = [[NSMutableArray alloc] init];
    
    for (int k = 0; k<numPixelsWide; k++) {
        NSMutableArray *yList = [[NSMutableArray alloc] init];
        [gridList addObject:yList];
    }
    
    for (int i = 0; i<numPixelsWide; i++) {
        for (int j = 0; j<numPixelsHigh; j++) {
            CSCell *viewToAdd = [self cellAtRect:CGRectMake(i*size.width, j*size.height, size.width, size.height) withColor:color];
            
            //Add view to 2 dimensional array
            NSMutableArray *yList = (NSMutableArray *)[gridList objectAtIndex:i];
            [yList insertObject:viewToAdd atIndex:j];
            
            [view addSubview:viewToAdd];
        }
    }
}

-(void)applyNeighborsForCellsInGrid
{
    
    int numCellsWide = [gridList count];
    int numCellsHigh;
    
    for (int i = 0; i<32; i++) {
        
        numCellsHigh = [[gridList objectAtIndex:i] count];
        
        for (int j = 0; j<numCellsHigh; j++) {
            //i j x y for views in grid
            //Add in neighbors
            CSCell *workingCell = (CSCell *)[[gridList objectAtIndex:i] objectAtIndex:j];
            
            if (j-1 >= 0) {
                workingCell.north = [self workingCell:workingCell cellAtHorizontal:i vertical:j-1];
            }
            if (j+1 <= numCellsHigh) {
                workingCell.south =  [self workingCell:workingCell cellAtHorizontal:i vertical:j+1];
            }
            if (i-1 >= 0) {
                workingCell.east = [self workingCell:workingCell cellAtHorizontal:i-1 vertical:j];
            }
            if (i+1 <= numCellsWide) {
                workingCell.west = [self workingCell:workingCell cellAtHorizontal:i+1 vertical:j];
            }
            
            //Diagonals
            
            if (j-1 >= 0 && i-1 >= 0) {
                workingCell.northEast = [self workingCell:workingCell cellAtHorizontal:i-1 vertical:j-1];
            }
            if (j-1 >= 0 && i+1 <= numCellsWide) {
                workingCell.northWest =  [self workingCell:workingCell cellAtHorizontal:i+1 vertical:j-1];
            }
            if (j+1 <= numCellsHigh && i+1 <= numCellsWide) {
                workingCell.southEast = [self workingCell:workingCell cellAtHorizontal:i+1 vertical:j+1];
            }
            if (j+1 <= numCellsHigh && i-1 >= 0) {
                workingCell.southWest = [self workingCell:workingCell cellAtHorizontal:i-1 vertical:j+1];
            }
        }
    }
}

-(CSCell *)workingCell:(CSCell *)workingCell cellAtHorizontal:(int)horizontal vertical:(int)vertical
{
    if (horizontal < 0) {
        horizontal = 0;
    }else if(horizontal > [gridList count]-1){
        horizontal = [gridList count]-1;
    }
    
    if (vertical < 0) {
        vertical = 0;
    }else if(vertical > 29-1){
        vertical = 29-1;
    }
    
    CSCell *returnCell = [[gridList objectAtIndex:horizontal] objectAtIndex:vertical];
    
    if (returnCell == workingCell) {
        //They are the same, so return nil
        returnCell = nil;
    }
    
    return returnCell;
}

-(void)clearView:(UIView *)view
{
    NSLog(@"Clearing view");
    for (UIView *subView in view.subviews) {
        subView.backgroundColor = [UIColor clearColor];
    }
}

-(CSCell *)cellAtRect:(CGRect)rect withColor:(UIColor *)color
{
    CSCell *returnView;
    
    returnView = [[CSCell alloc] initWithFrame:rect];
    [returnView setBackgroundColor:color];
    
    return returnView;
}

#pragma view to PNG

- (IBAction)saveImage:(id)sender {
    savedImage = [self renderView:drawView];
    savedImage = [self imageWithImage:savedImage scaledToSize:CGSizeMake(savedImage.size.width/2, savedImage.size.height/2)];
    
    UIActionSheet *share = [[UIActionSheet alloc] initWithTitle:@"share your pixem?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"to photos", @"email", @"twitter", @"facebook", @"pixem tumblr", @"view other pixems", nil];
    [share showInView:self.view];
}

-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, [[UIScreen mainScreen] scale]);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    newImage = [UIImage imageWithData:UIImagePNGRepresentation(newImage)];
    
    return newImage;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *title;
    NSString *body;
    if (error) {
        title = @"Warning";
        body = @"Image failed to save";
    }else{
        title = @"Sweet";
        body = @"Image saved to photo library";
    }
    UIAlertView *saved = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [saved show];
}

- (UIImage*)renderView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(ctx, view.bounds);
    
    [[view layer] renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)newEmailToUser:(NSString *)user sparseText:(BOOL)sparse
{
    MFMailComposeViewController *mf = [[MFMailComposeViewController alloc] init];
    mf.mailComposeDelegate = self;
    
    [mf setSubject:@"A pixem from a friend"];
    
    if (user) {
        [mf setToRecipients:[NSArray arrayWithObject:user]];
    }
    
    [mf addAttachmentData:[NSData dataWithData:UIImagePNGRepresentation(savedImage)] mimeType:@"image/png" fileName:@"pixem.png"];
    
    NSMutableString *bodyText = [NSMutableString stringWithString:@"Created with <a href = 'http://itunes.com/apps/pixem'>Pixem</a>"];
    
    if (!sparse) {
        [bodyText appendString:@" More: <a href = 'http://www.pixemart.tumblr.com'>pixemart.tumblr.com</a>"];
    }
    
    [mf setMessageBody:bodyText isHTML:YES];
    
    [self presentViewController:mf animated:YES completion:nil];
}

-(void)socialPostTo:(NSString *)service
{
    SLComposeViewController *compose = [SLComposeViewController composeViewControllerForServiceType:service];
    [compose addImage:savedImage];
    [compose setInitialText:@"pixem http://itunes.com/apps/pixem"];
    [self presentViewController:compose animated:YES completion:nil];
}

#pragma Mail view dismiss

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload
{
    drawView = nil;
    colorView = nil;
    liveButton = nil;
    clearButton = nil;
    saveButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)setDrawColor:(UIColor *)color
{
    drawColor = color;
    
    if ([drawColor isEqual:[UIColor clearColor]]) color = [UIColor blackColor];
    
    colorView.backgroundColor = color;
    self.view.backgroundColor = color;
    controlView.backgroundColor = color;
}

-(void)setButtonColor:(UIColor *)color
{
    colorLabel.textColor = color;
    liveButton.titleLabel.textColor = color;
    clearButton.titleLabel.textColor = color;
    saveButton.titleLabel.textColor = color;
    pickButton.titleLabel.textColor = color;
}

- (IBAction)sampleColor:(id)sender {
    if (sampling) {
        [self setSampling:NO];
    }else{
        [self setSampling:YES];
    }
}

-(void)setSampling:(BOOL)doSample
{
    if (doSample) {
        sampling = YES;
        [pickButton setTitle:@"pickn" forState:UIControlStateNormal];
    }else{
        sampling = NO;
        [pickButton setTitle:@"pick" forState:UIControlStateNormal];
    }
}

- (IBAction)setBlack:(id)sender
{
    [self setDrawColor:[UIColor blackColor]];
}

- (IBAction)setWhite:(id)sender
{
    [self setDrawColor:[UIColor clearColor]];
}

- (IBAction)clearImage:(id)sender {
    UIActionSheet *warning = [[UIActionSheet alloc] initWithTitle:@"clear your pixem?" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:@"clear!" otherButtonTitles: nil];
    [warning showInView:self.view];
}

- (IBAction)liveToggle:(id)sender {
    UIButton *toggle = (UIButton *)sender;
    if (!liveTimer && !gravityTimer) {
        UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:@"living and gravity alter your drawing, continue?" delegate:self cancelButtonTitle:@"no" destructiveButtonTitle:nil otherButtonTitles: @"live!", @"gravity!", nil];
        [alert showInView:self.view];
    }else{
        [motionManager stopAccelerometerUpdates];
        [self hideLiving:YES animated:YES title:@"stopping"];
        [toggle setTitle:@"move" forState:UIControlStateNormal];
        [liveTimer invalidate];
        liveTimer = nil;
        [gravityTimer invalidate];
        gravityTimer = nil;
    }
}

#pragma UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"want to undo?"])
    {
        if (buttonIndex == 1) {
            //Restore to last saved pixem
            [self restorePixemFromArray:lastState];
        }
    }
}

#pragma UIActionSheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet.title isEqualToString:@"share your pixem?"]) {
        if (buttonIndex == 0) {
            //Photos
            UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }else if(buttonIndex == 1){
            //Email
            [self newEmailToUser:nil sparseText:NO];
        }else if(buttonIndex == 2){
            //Twitter post
            [self socialPostTo:SLServiceTypeTwitter];
        }else if(buttonIndex == 3){
            //Facebook post
            [self socialPostTo:SLServiceTypeFacebook];
        }else if(buttonIndex == 4){
            //Post to tumblr
            [self newEmailToUser:@"98meglur@tumblr.com" sparseText:YES];
        }else if(buttonIndex == 5){
            //View tumblr
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.pixemart.tumblr.com"]];
        }
    }else if([actionSheet.title isEqualToString:@"clear your pixem?"]){
        if (buttonIndex == 0) {
            //Destruct, clear pixem
            [self clearView:drawView];
        }
    }else if([actionSheet.title isEqualToString:@"living and gravity alter your drawing, continue?"])
    {
        if (buttonIndex == 0) {
            //Start living then!
            [self hideLiving:NO animated:YES title:@"living"];
            [liveButton setTitle:@"stop" forState:UIControlStateNormal];
            lastState = [self arrayOfColorsInPixem];
            liveTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(stepLife) userInfo:nil repeats:YES];
        }else if(buttonIndex == 1){
            //Step gravity now!
            [motionManager startAccelerometerUpdates];
            [self hideLiving:NO animated:YES title:@"gravity"];
            [liveButton setTitle:@"stop" forState:UIControlStateNormal];
            lastState = [self arrayOfColorsInPixem];
            gravityTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(stepGravity) userInfo:nil repeats:YES];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

@end
