//
//  PathOverlayRenderer.m
//  Pigeon
//
//  Created by James Bucanek on 12/23/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "PathOverlayRenderer.h"

#define NO_TEST_LOG
#import "Pigeon.h"
#import "PigeonMath.h"
#import "PathOverlay.h"


@implementation PathOverlayRenderer

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
	// Draw the accuracy area around the return location and a line from the user's current location.
	
	// Note: This method only uses Core Graphics drawing functions. Use of UIKit is possible,
	//	but there are a number of restrictions, so I just avoid them.
	
	PathOverlay* overlay = self.overlay;
	if (!MKMapRectIntersectsRect(mapRect,overlay.boundingMapRect))
		return;
	
	CGPoint linePoints[2];
	linePoints[0] = [self pointForMapPoint:overlay.userMapPoint];
	linePoints[1] = [self pointForMapPoint:overlay.returnMapPoint];
#define fromPoint linePoints[0]
#define toPoint linePoints[1]
	
	// Create a rectangle the encompasses both points (at opposite corners)
	CGRect boundRect = CGRectStandardize(CGRectMake(fromPoint.x,
													fromPoint.y,
													toPoint.x-fromPoint.x,
													toPoint.y-fromPoint.y));
	CGFloat shortEdge = boundRect.size.height;
	CGFloat longEdge = boundRect.size.width;
	if (shortEdge>longEdge)
		{
		shortEdge = longEdge;
		longEdge = boundRect.size.height;
		}
	if (longEdge<2.0)
		// Nothing to draw, and avoids the edge condition where longEdge==0
		return;
	// Calculate how square the rectangle is, with 0.0 being completely flat
	//	and 1.0 being perfectly square.
	CGFloat squareness = shortEdge/longEdge;
	TESTLog(@"squareness = %f",squareness);
	CGMutablePathRef curveRef = NULL;
	if (squareness>0.125)
		{
		// Calculate the angle from the starting point to the ending point
		double angle = CGATan2(toPoint.y-fromPoint.y,toPoint.x-fromPoint.x);
		// Calculate the midpoint between the starting point and the ending point
		CGPoint midPoint = CenterOfRect(boundRect);
#ifndef NO_TEST_LOG
		// Debugging: draw the center point on the map (green)
		CGRect ctlPoint = CGRectMake(midPoint.x,midPoint.y,100.0,100.0);
		CGContextSetRGBFillColor(context,0.0,1.0,0.0,1.0);
		CGContextFillRect(context,ctlPoint);
#endif
		// Calculate a point, offset from center, perpendicular from the direct line,
		//	the distance relative to the shortest side times the "squareness".
		angle += M_PI_2;		// Rotate left, 90°
		CGFloat offset = shortEdge*squareness*0.667;
		midPoint.x += CGCos(angle)*offset;
		midPoint.y += CGSin(angle)*offset;
#ifndef NO_TEST_LOG
		// Debugging: draw the quadraic control point on the map (purple)
		ctlPoint = CGRectMake(midPoint.x,midPoint.y,100.0,100.0);
		CGContextSetRGBFillColor(context,1.0,0.0,1.0,1.0);
		CGContextFillRect(context,ctlPoint);
#endif
		curveRef = CGPathCreateMutable();
		CGPathMoveToPoint(curveRef,NULL,fromPoint.x,fromPoint.y);
		CGPathAddQuadCurveToPoint(curveRef,NULL,midPoint.x,midPoint.y,toPoint.x,toPoint.y);
		}

	// Draw the line
	CGFloat roadWidth = MKRoadWidthAtZoomScale(zoomScale);
	TESTLog(@"roadWidth=%f",roadWidth);
	CGContextSetLineWidth(context,roadWidth);
	CGContextSetLineCap(context,/*kCGLineCapSquare*/kCGLineCapRound);
	if (_lightPath)
		{
		// Draw a light path (used for satellite views)
		// Fill with a black, 60% transparent, underlay
		CGContextSetRGBStrokeColor(context,0.0,0.0,0.0,0.6);
		if (curveRef!=NULL)
			{
			CGContextAddPath(context,curveRef);
			CGContextStrokePath(context);
			}
		else
			{
			CGContextStrokeLineSegments(context,linePoints,2);
			}
		// Overwrite with a white line
		CGContextSetRGBStrokeColor(context,1.0,1.0,1.0,1.0);
		}
	else
		{
		// Draw a dark path (used for standard map view)
		CGContextSetRGBStrokeColor(context,0.0,0.0,0.0,1.0);
		}
	CGFloat dashes[2] = { roadWidth*2.5, roadWidth*1.5 };
	CGContextSetLineDash(context,0,dashes,2);
	if (curveRef!=NULL)
		{
		CGContextAddPath(context,curveRef);
		CGContextStrokePath(context);
		}
	else
		{
		CGContextStrokeLineSegments(context,linePoints,2);
		}
}

@end
