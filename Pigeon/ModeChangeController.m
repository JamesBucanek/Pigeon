//
//  ModeChangeController
//  Pigeon
//
//  Created by James Bucanek on 12/18/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <QuartzCore/QuartzCore.h>

#import "ModeChangeController.h"

#import "PigeonMath.h"
#import "RoundedRectView.h"

#define kIndicatorMargin		14.0		// margin between option views and the edge of the indicator view

#define kSliderAnimationKey		@"slideTo"
#define kFadeAnimationKey		@"fadeAway"


@interface ModeChangeController () // private
{
	NSString*			nibName;
	NSPointerArray*		imageViews;
	NSPointerArray*		labelViews;
}
@property (weak,nonatomic) IBOutlet RoundedRectView*	indicatorView;
- (void)prepareHighlightedImage:(UIImageView*)imageView;
- (UIImageView*)imageForOption:(NSUInteger)index;
- (UILabel*)labelForOption:(NSUInteger)index;
- (void)discardView;
@end

@implementation ModeChangeController

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self)
		{
        nibName = name;

		_cornerRadius = 10.0;
		_lineWidth = 2.0;
		_strokeColor = [UIColor greenColor];
		_fillColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
}
    return self;
}

- (UIView*)view
{
	if (_view==nil)
		{
		[[NSBundle mainBundle] loadNibNamed:nibName
									  owner:self
									options:nil];
		
		// The constraints in IB are constructed so the rounded rectangle
		//	view is correctly sized for the overall layout.
		[_view layoutIfNeeded];

		// Based on the view tags, construct an array of the image and
		//	label views associated with each option.
		_optionCount = 0;
		imageViews = [NSPointerArray strongObjectsPointerArray];
		labelViews = [NSPointerArray strongObjectsPointerArray];
		for ( UIView* view in _view.subviews )
			{
			NSUInteger tag = view.tag;
			if (tag!=0)
				{
				if (tag>_optionCount)
					{
					_optionCount = tag;
					imageViews.count = tag;
					labelViews.count = tag;
					}
				NSPointerArray* viewArray = nil;
				if ([view isKindOfClass:[UIImageView class]])
					{
					[self prepareHighlightedImage:(UIImageView*)view];
					viewArray = imageViews;
					}
				if ([view isKindOfClass:[UILabel class]])
					viewArray = labelViews;
				if (viewArray!=nil)
					[viewArray replacePointerAtIndex:tag-1 withPointer:(__bridge void*)view];
				}
			}
		}
	return _view;
}

- (void)prepareHighlightedImage:(UIImageView*)imageView
{
	// The image view's regular image (in the nib) is actually the highlighted image.
	// Take its nib image and make that the highlighted image, and then create a
	//	desaturated copy of the image and make it the regular image.
	UIImage* image = imageView.image;
	imageView.highlightedImage = image;
	CIImage* originalImage = [CIImage imageWithCGImage:[image CGImage]];
	CIFilter* desaturationFilter = [CIFilter filterWithName:@"CIColorControls" keysAndValues:
									@"inputImage", originalImage,
									@"inputSaturation", @(0.0),
									nil];
    // Generate the filtered image
    CIImage *filteredImage = [desaturationFilter outputImage];

	// Turn the CIImage back into a UIImage and make it the un-highlighted image
    UIImage *bwImg = [UIImage imageWithCIImage:filteredImage];
	imageView.image = bwImg;
}

- (void)discardView
{
	[_view removeFromSuperview];
	imageViews = nil;
	labelViews = nil;
	_indicatorView = nil;
	_view = nil;
}

- (UIImageView*)imageForOption:(NSUInteger)index
{
	if (index<imageViews.count)
		return (__bridge UIImageView*)[imageViews pointerAtIndex:index];
	return nil;
}

- (UILabel*)labelForOption:(NSUInteger)index
{
	if (index<labelViews.count)
		return (__bridge UILabel*)[labelViews pointerAtIndex:index];
	return nil;
}

- (void)animateSwitchFrom:(NSUInteger)fromIndex
					   to:(NSUInteger)toIndex
				   inView:(UIView*)parentView
			   centeredAt:(CGPoint)center
{
	// Animate a setting change from the option at index fromInto to the one at toIndex.

	BOOL newView = NO;
	if (_view==nil)
		{
		// The setting animation is not being display or has never been loaded.
		// Load, position, and insert the view.
		[parentView addSubview:self.view];
		self.view.center = center;
		newView = YES;
		}
	
	if (_indicatorView==nil)
		{
		RoundedRectView* rectView = [[RoundedRectView alloc] initWithFrame:CGRectMake(0.0,0.0,100,100.0)];
		rectView.lineWidth = _lineWidth;
		rectView.cornerRadius = _cornerRadius;
		rectView.strokeColor = _strokeColor;
		rectView.fillColor = _fillColor;
		[_view insertSubview:rectView atIndex:0];
		_indicatorView = rectView;
		}
	
	// Highlight the views for the setting that we're switching to, and dim the others.
	for ( NSUInteger i=0; i<labelViews.count; i++ )
		{
		BOOL selection = ( i==toIndex );
		// Make the title text black (selected) or grey (not selected)
		UILabel* settingLabel = [self labelForOption:i];
		settingLabel.textColor = ( selection ? [UIColor darkTextColor] : [UIColor lightGrayColor] );
		// Make the image normal (selected) or desaturated (not selected)
		UIImageView* imageView = [self imageForOption:i];
		imageView.highlighted = selection;
		}
	
	// Set the scene
	CGRect fromFrame = [self roundedRectForOption:fromIndex];
	if (newView)
		_indicatorView.frame = fromFrame;
	_view.alpha = 1.0;
	
	// Animate the view to the new position and out
	CGRect toFrame = [self roundedRectForOption:toIndex];
//	CGPoint toCenter = CenterOfRect(toFrame);
	[UIView animateWithDuration:0.4
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 _indicatorView.frame = toFrame;
						 }
					 completion:^(BOOL finished) {
						 // After the slide is finished, start a fade out animation
						 if (finished)
							 {
							 [UIView animateWithDuration:0.20
												   delay:0.25
												 options:UIViewAnimationOptionCurveEaseOut
											  animations:^{
												  _view.alpha = 0.0;
											  }
											  completion:^(BOOL finished) {
												  if (finished)
													  [self discardView];
											  }];
							 }
						 }];
}

- (CGRect)roundedRectForOption:(NSUInteger)index
{
	CGRect rect = _view.bounds;					// Get the width of the view
	CGRect optionRect = [self imageForOption:index].frame;
	rect.origin.y = CGRectGetMinY(optionRect)-kIndicatorMargin;
	rect.size.height = optionRect.size.height+kIndicatorMargin*2;
	return rect;
}

@end
