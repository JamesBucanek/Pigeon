//
//  HelpBubbleController.m
//  Pigeon
//
//  Created by James Bucanek on 2/4/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import "HelpBubbleController.h"

#import "HelpBubbleView.h"


#define kPresentAnimationDuration	0.35
#define kPresentAnimationDelay		0.1
#define kDismissAnimationDuration1	0.15
#define kDismissAnimationDuration2	0.2
#define kDismissAnimationGrowScale		1.2		// grow 20%
#define kDismissAnmiationShrinkScale	0.1		// shrink to 10%


@interface HelpBubbleController ()
{
	NSString*	nibName;
	CGRect		originRect;
}
- (void)setOriginTransform;
@end


@implementation HelpBubbleController

- (id)initWithNib:(NSString*)name
{
    self = [super init];
    if (self)
		{
        nibName = name;
		}
    return self;
}

- (void)presentForView:(UIView *)targetView fromView:(UIView *)originView
{
	// Load the nib
	if (_bubbleView==nil)
		[[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
	
	// Calculate where the help bubble view should be positioned, relative to the view
	//	it will point to.
	CGPoint targetPoint = [HelpBubbleView pointOnEdge:(_bubbleView.pointerEdge+2)%4
											   ofView:targetView
										   withOffset:0];
	CGRect bubbleFrame = [_bubbleView framePointingAt:targetPoint];
	originRect = originView.frame;
	
	// Place the view at its final position
	_bubbleView.frame = bubbleFrame;
	[targetView.superview addSubview:_bubbleView];
	
	// Set the bubble view's transformation and opacity at what they should be
	//	at the beginning of its animation.
	// Start by calculating a transform change from the start location to the end location
	[self setOriginTransform];
	
	// Now animate the view from this shrunk-down, offset, mostly invisible state to it's final,
	//	full-sized, opaque, position.
	[UIView animateWithDuration:kPresentAnimationDuration
						  delay:kPresentAnimationDelay
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 _bubbleView.transform = CGAffineTransformIdentity;
						 _bubbleView.alpha = 1.0;
						 }
					 completion:nil];
}

- (void)dismiss
{
	CGPoint anchorPoint = [_bubbleView pointPoint];
	CGPoint centerPoint = _bubbleView.center;
	CGPoint centerDelta = CGPointMake(centerPoint.x-anchorPoint.x,centerPoint.y-anchorPoint.y);
	
	[UIView animateWithDuration:kDismissAnimationDuration1
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 // Step 1: Make the view grow, offsetting its center so the anchor point doesn't change
						 CGAffineTransform transform;
						 CGFloat xTrans = anchorPoint.x+centerDelta.x*kDismissAnimationGrowScale-centerPoint.x;
						 CGFloat yTrans = anchorPoint.y+centerDelta.y*kDismissAnimationGrowScale-centerPoint.y;
						 transform = CGAffineTransformMakeTranslation(xTrans,yTrans);
						 transform = CGAffineTransformScale(transform,
															kDismissAnimationGrowScale,
															kDismissAnimationGrowScale);
						 _bubbleView.transform = transform;
					 } completion:^(BOOL finished) {
						 // The instant the grow scale is done, start to shrink it
						 [UIView animateWithDuration:kDismissAnimationDuration2
											   delay:0.0
											 options:UIViewAnimationOptionCurveEaseIn
										  animations:^{
											  // Step 2: shrink the view down to almost nothing, while fading out
											  CGAffineTransform transform;
											  CGFloat xTrans = anchorPoint.x+centerDelta.x*kDismissAnmiationShrinkScale-centerPoint.x;
											  CGFloat yTrans = anchorPoint.y+centerDelta.y*kDismissAnmiationShrinkScale-centerPoint.y;
											  transform = CGAffineTransformMakeTranslation(xTrans,yTrans);
											  transform = CGAffineTransformScale(transform,
																				 kDismissAnmiationShrinkScale,
																				 kDismissAnmiationShrinkScale);
											  _bubbleView.transform = transform;
											  _bubbleView.alpha = 0.0;
										  } completion:^(BOOL finished) {
											  // All done: remove the bubble view
											  [_bubbleView removeFromSuperview];
										  }];
					 }];
}

- (void)retract
{
	// Instead of dismissing the bubble with a bounce, send it back to where it came from
	[UIView animateWithDuration:kPresentAnimationDuration
						  delay:kPresentAnimationDelay
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 [self setOriginTransform];
					 }
					 completion:^(BOOL finished) {
						 // All done: remove the bubble view
						 [_bubbleView removeFromSuperview];
					 }];
}

- (void)setOriginTransform
{
	// Set the bubble view's transformation and opacity so it appears in a shrunk-down
	//	size over the originRect. This is used to make the bubble view appear to "fly out"
	//	of the help button, and also to return it.
	// Start by calculating a transform change from the start location to the end location
	CGRect bubbleFrame = _bubbleView.frame;
	CGAffineTransform transform = CGAffineTransformMakeTranslation(CGRectGetMidX(originRect)-CGRectGetMidX(bubbleFrame),
																   CGRectGetMidY(originRect)-CGRectGetMidY(bubbleFrame));
	// Then shrink the view to 1/10th its final size (scale transforms are centered)
	transform = CGAffineTransformScale(transform,0.1,0.1);
	_bubbleView.transform = transform;
	_bubbleView.alpha = 0.2;
}

@end
