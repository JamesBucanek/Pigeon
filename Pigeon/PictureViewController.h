//
//  PictureViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/27/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PictureScrollView;
@class SavedLocation;

//
// The controller for the picture scene
//

@interface PictureViewController : UIViewController <UIAlertViewDelegate>

// outlets
@property (weak,nonatomic) IBOutlet PictureScrollView* scrollView;

// data model
@property (strong,nonatomic) SavedLocation* location;
@property (nonatomic) NSUInteger pictureIndex;
@property (readonly,nonatomic) UIImage* image;

// actions
- (IBAction)trashPicture:(id)sender;

@end
