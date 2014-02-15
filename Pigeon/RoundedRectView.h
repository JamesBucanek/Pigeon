//
//  RoundedRectView.h
//  Pigeon
//
//  Created by James Bucanek on 12/18/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

//
// A UIView that draws a rounded-rectangle background, optionally
//	with a stroked border.
//

@interface RoundedRectView : UIView
{
	@protected
	UIBezierPath*	path;
	CGRect			cachedBounds;
}

@property (nonatomic) CGFloat					cornerRadius;
@property (nonatomic) CGFloat					lineWidth;
@property (strong,nonatomic) UIColor*			strokeColor;
@property (strong,nonatomic) UIColor*			fillColor;

@property (readonly,nonatomic) UIBezierPath*	path;

@end
