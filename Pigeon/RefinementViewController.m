//
//  RefinementViewController.m
//  Pigeon
//
//  Created by James Bucanek on 1/7/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import "RefinementViewController.h"

#import "Refiner.h"


#define kMinutesComponent	0
#define kSecondsComponent	1

#define kSecondsIncrement	5		// choose time in 5 second increments


@interface RefinementViewController ()
- (void)updateDurationLabel;
@end

@implementation RefinementViewController

+ (NSString*)localizedRefinementDuration:(NSTimeInterval)duration
{
	NSMutableString* refineText = [NSMutableString string];
	NSUInteger secs = (NSUInteger)round(duration);
	if (secs!=0)
		{
		NSUInteger mins = secs/60;
		secs %= 60;
		if (mins!=0)
			{
			[refineText setString:[NSString stringWithFormat:(mins==1?@"%u min":@"%u mins"),(unsigned int)mins]];
			if (secs!=0)
				[refineText appendString:@", "];
			}
		if (secs!=0)
			{
			[refineText appendString:[NSString stringWithFormat:(secs==1?@"%u sec":@"%u secs"),(unsigned int)secs]];
			}
		}
	else
		{
		[refineText setString:@"none"];
		}
	return [refineText description];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Configure the date picker
	NSUInteger duration = (NSUInteger)[Refiner duration];
	[_picker selectRow:duration/60
		   inComponent:kMinutesComponent
			  animated:NO];
	[_picker selectRow:(duration%60)/kSecondsIncrement
		   inComponent:kSecondsComponent
			  animated:NO];
	[self updateDurationLabel];
}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

- (void)updateDurationLabel
{
	_durationLabel.text = [RefinementViewController localizedRefinementDuration:[Refiner duration]];
}

#pragma mark <UIPickerViewDataSource>

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 2;	// "Minutes" and "Seconds"
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (component==kMinutesComponent)
		{
		// Minutes
		return (kRefinementDurationMax/60);		// number of minute choices == max time in minutes
		}
	else /* if (component==kSecondsComponent) */
		{
		// Seconds
		return (60/kSecondsIncrement);
		}
}

#pragma mark <UIPickerViewDelegate>

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (component==kMinutesComponent)
		{
		// Minutes
		return [NSString stringWithFormat:@"%i",(int)row];
		}
	else /* if (component==kSecondsComponent) */
		{
		// Seconds
		return [NSString stringWithFormat:@"%i",(int)row*kSecondsIncrement];
		}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	NSUInteger duration = [pickerView selectedRowInComponent:kSecondsComponent]*kSecondsIncrement;
	duration += [pickerView selectedRowInComponent:kMinutesComponent]*60;
	[[NSUserDefaults standardUserDefaults] setInteger:duration forKey:kPreferenceRefinementDuration];
	[self updateDurationLabel];
}

@end
