//
//  RefinementViewController.h
//  Pigeon
//
//  Created by James Bucanek on 1/7/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RefinementViewController : UIViewController <UIPickerViewDelegate,
														UIPickerViewDataSource>

+ (NSString*)localizedRefinementDuration:(NSTimeInterval)duration;

@property (weak,nonatomic) IBOutlet UIPickerView* picker;
@property (weak,nonatomic) IBOutlet UILabel* durationLabel;

@end
