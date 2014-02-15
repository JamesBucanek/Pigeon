//
//  HelpBubbleView.m
//  Pigeon
//
//  Created by James Bucanek on 2/4/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import "HelpBubbleView.h"

#import "PigeonMath.h"


@implementation HelpBubbleView

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self)
//		{
//		// Set the defaults
//		-- all of this subclass' defaults are 0
//		}
//    return self;
//}

- (void)setPointerEdge:(NSUInteger)pointerEdge
{
	_pointerEdge = pointerEdge;
	path = nil;
}

- (void)setPointerLength:(CGFloat)pointerLength
{
	_pointerLength = pointerLength;
	path = nil;
}

- (void)setPointOffset:(CGFloat)pointOffset
{
	_pointOffset = pointOffset;
	path = nil;
}

- (CGPoint)pointPoint
{
	// Return the point where the pointer points to
	return [HelpBubbleView pointOnEdge:(CGRectEdge)_pointerEdge ofView:self withOffset:_pointOffset];
}

+ (CGPoint)pointOnEdge:(CGRectEdge)edge ofView:(UIView*)view withOffset:(CGFloat)offset
{
	CGRect frame = view.frame;
	switch (edge) {
		default:
		case CGRectMinXEdge: return CGPointMake(CGRectGetMinX(frame),CGRectGetMidY(frame)+offset);
		case CGRectMinYEdge: return CGPointMake(CGRectGetMidX(frame)+offset,CGRectGetMinY(frame));
		case CGRectMaxXEdge: return CGPointMake(CGRectGetMaxX(frame),CGRectGetMidY(frame)+offset);
		case CGRectMaxYEdge: return CGPointMake(CGRectGetMidX(frame)+offset,CGRectGetMaxY(frame));
	}
}

- (CGRect)framePointingAt:(CGPoint)point
{
	// Return the frame that would have the pointer pointing at |point|.
	
	// Offset the origin of the frame by the difference between where it's currently pointing
	//	to and where we'd like it to point.
	CGRect frame = self.frame;
	CGPoint naturalPoint = self.pointPoint;
	frame.origin.x -= naturalPoint.x-point.x;
	frame.origin.y -= naturalPoint.y-point.y;
	return frame;
}

#define kPointerBaseProportion		0.25		// size of pointer base proportional to edge
#define kPointerBaseSlideProportion	0.5			// base offset propotional to point offset
#define kPointerBaseWidthMin		(lineWidth*3)
#define kPointerBaseWidthMax		(_pointerLength/2)
#define EdgeIsHorizontal(EDGE) (((EDGE)&0x1)!=0)

- (UIBezierPath*)path
{
	// Return, or lazily create, the Bezier path that describes the rounded rectangle
	CGRect bounds = self.bounds;
	if (path==nil || !CGRectEqualToRect(bounds,cachedBounds))
		{
		CGFloat lineWidth = self.lineWidth;
		if (_pointerLength>lineWidth)
			{
			cachedBounds = bounds;
			
			// Inset by half the width of the line so it doesn't get clipped
			bounds = CGRectInset(bounds,lineWidth/2,lineWidth/2);
			
			// Calculate the rect of the rounded rect by insetting from the side
			//	that will have the pointer segment.
			CGRect pointerRect;
			CGRect roundRect;
			CGRectDivide(bounds,&pointerRect,&roundRect,_pointerLength,(CGRectEdge)_pointerEdge);
			// Calculate the length of the staight edges in the rounded rectangle
			CGFloat cornerRadius = self.cornerRadius;
			CGRect straightRect = CGRectInset(roundRect,cornerRadius,cornerRadius);
			
			// Starting at the lower left corner, build the rounded rect clockwise,
			//	inserting the "pointer" segment on the side specified by _pointerEdge.
			CGPoint turtle = CGPointMake(CGRectGetMinX(roundRect),CGRectGetMaxY(roundRect)-cornerRadius);
			path = [UIBezierPath bezierPath];
			[path moveToPoint:turtle];
			for ( CGRectEdge edge=CGRectMinXEdge; edge<=CGRectMaxYEdge; edge++ )
				{
				static CGFloat XDirection[] = { 0, 1, 0, -1, 0 };	// X direction of travel for each edge
				static CGFloat YDirection[] = { -1, 0, 1, 0, -1 };	// Y direction of travel for each edge
				if (edge==_pointerEdge)
					{
					CGPoint baseCenter;
					CGFloat halfBaseWidth;
					if (EdgeIsHorizontal(edge))
						{
						// This is a horizontal edge
						baseCenter = CGPointMake(CGRectGetMidX(roundRect),turtle.y);
						halfBaseWidth = straightRect.size.width*(kPointerBaseProportion/2);
						}
					else
						{
						// This is vertical edge
						baseCenter = CGPointMake(turtle.x,CGRectGetMidY(roundRect));
						halfBaseWidth = straightRect.size.height*(kPointerBaseProportion/2);
						}
					// Round up that base width to the nearest integer and make sure it's not smaller than the minimum
					halfBaseWidth = CGCeiling(CGMin(CGMax(halfBaseWidth,kPointerBaseWidthMin/2),kPointerBaseWidthMax/2));
					// Offset the point by the "length" (really the height) of the pointer by
					//	moving the point perpendicular to the current direction, by using the previous
					//	edge as the direction.
					CGRectEdge previousEdge = ( edge==CGRectMinXEdge ? CGRectMaxYEdge : edge-1 );
					CGPoint pointPoint = CGPointMake(baseCenter.x+(_pointerLength-lineWidth)*XDirection[previousEdge],
													 baseCenter.y+(_pointerLength-lineWidth)*YDirection[previousEdge]);
					// Offset the point and its base from the dead center of the rect.
					// If 0, the point will be centered over the edge. Offsetting it creates a slighly tilted triangle.
					if (EdgeIsHorizontal(edge))
						{
						pointPoint.x += _pointOffset;
						baseCenter.x += _pointOffset*kPointerBaseSlideProportion;
						}
					else
						{
						pointPoint.y += _pointOffset;
						baseCenter.y += _pointOffset*kPointerBaseSlideProportion;
						}
					// Finally, calculate the first and second points of the base, as they
					//	occur in the Bezier curve.
					CGPoint firstBaseCorner = CGPointMake(baseCenter.x-halfBaseWidth*XDirection[edge],
														  baseCenter.y-halfBaseWidth*YDirection[edge]);
					CGPoint secondBaseCorner = CGPointMake(baseCenter.x+halfBaseWidth*XDirection[edge],
														   baseCenter.y+halfBaseWidth*YDirection[edge]);
					// Add the three points of the pointer to the curve
					[path addLineToPoint:firstBaseCorner];
					[path addLineToPoint:pointPoint];
					[path addLineToPoint:secondBaseCorner];
					}
				// Complete the segment to the next rounded corner
				turtle.x += straightRect.size.width*XDirection[edge];
				turtle.y += straightRect.size.height*YDirection[edge];
				[path addLineToPoint:turtle];
				// Create the rounded corner by adding a quadratic curve with the control point at the corner
				CGPoint cornerPoint = CGPointMake(turtle.x+cornerRadius*XDirection[edge],
												  turtle.y+cornerRadius*YDirection[edge]);
				// Caculate the end of the curve by moving the point along the next edge
				turtle = CGPointMake(cornerPoint.x+cornerRadius*XDirection[edge+1],
									 cornerPoint.y+cornerRadius*YDirection[edge+1]);
				[path addQuadCurveToPoint:turtle controlPoint:cornerPoint];
				}
			[path closePath];
			path.lineWidth = lineWidth;
			path.lineCapStyle = kCGLineCapSquare;
			}
		else
			{
			// There's no pointer length, so just create a rounded rect
			return [super path];
			}
		}
	return path;
}

@end
