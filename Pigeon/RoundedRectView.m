//
//  RoundedRectView.m
//  Pigeon
//
//  Created by James Bucanek on 12/18/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "RoundedRectView.h"

@implementation RoundedRectView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
		{
		// rounded rect views are never opaque, because the corners are transparent
        self.opaque = NO;
		self.clearsContextBeforeDrawing = YES;
		self.backgroundColor = nil;
		
		// Set the defaults for programatically created instances
		_cornerRadius = 20.0;
		_lineWidth = 6.0;
		}
    return self;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
	_cornerRadius = cornerRadius;
	path = nil;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
	_lineWidth = lineWidth;
	path = nil;
}

- (UIBezierPath*)path
{
	// Return, or lazily create, the Bezier path that describes the rounded rectangle
	CGRect bounds = self.bounds;
	if (path==nil || !CGRectEqualToRect(bounds,cachedBounds))
		{
		cachedBounds = bounds;
		bounds = CGRectInset(bounds,_lineWidth/2,_lineWidth/2);
		path = [UIBezierPath bezierPathWithRoundedRect:bounds
										  cornerRadius:_cornerRadius];
		path.lineWidth = _lineWidth;
		}
	return path;
}

- (void)drawRect:(CGRect)rect
{
	UIBezierPath* rectPath = self.path;
	
	// Fill first
	if (_fillColor!=nil)
		{
		[_fillColor setFill];
		[rectPath fill];
		}
	
	// Stroke last
	if (_strokeColor!=nil)
		{
		[_strokeColor setStroke];
		[rectPath stroke];
		}
}

@end
