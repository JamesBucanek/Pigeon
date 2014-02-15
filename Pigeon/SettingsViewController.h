//
//  SettingsViewController.h
//  Pigeon
//
//  Created by James Bucanek on 12/14/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <UIKit/UIKit.h>

//
// The controller for the settings scene
//

@interface SettingsViewController : UITableViewController

@property (weak,nonatomic) IBOutlet UITableViewCell*	refineTimeCell;
@property (weak,nonatomic) IBOutlet UISwitch*			synchronizeButton;
@property (weak,nonatomic) IBOutlet UISwitch*			savePicturesButton;

- (IBAction)toggleiCloud:(id)sender;
- (IBAction)toggleSavePicture:(id)sender;

@end
