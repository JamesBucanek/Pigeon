//
//  AccuracyOverlayRenderer.m
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "AccuracyOverlayRenderer.h"

#import "PigeonMath.h"


#define kReturnCircleLineWidth			8.0					// Thickness of return circle outline
#define kReturnCircleRadius				20.0				// Radius of return circle in points
#define kReturnCircleLineColorRGBA		1.0,0.0,0.0,1.0		// Color of return circle

#define AccuracyFillRGBA(ACCURATE)		1.0,0.5+(ACCURATE)/2,0.5+(ACCURATE)/2,0.5	// ACCURATE should be 0.0...1.0
#define kInaccurateInnerColorRGBA		1.0,0.3,0.3,0.5		// Inner gradient color
#define kInaccurateOuterColorRGBA		1.0,0.9,0.9,0.5		// Outer gradient color

@implementation AccuracyOverlayRenderer

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
	// Draw the accuracy area around the return location and a line from the user's current location.
	
	// Note: This method only uses Core Graphics drawing functions. Use of UIKit is possible,
	//	but there are a number of restrictions, so I just avoid it.
	
	CGFloat circleRadius = kReturnCircleRadius/zoomScale;
	
	// Calculate the rect for the accuracy circle
	// The map bounds of the return overlay object describes the accuracy circle of the location
	MKMapRect accuracyMapRect = self.overlay.boundingMapRect;
	CGRect accuracyRect = [self rectForMapRect:accuracyMapRect];
	CGPoint accuracyCenter = CenterOfRect(accuracyRect);
	
	// Create the bounding rect for the return circle
	CGRect minRect = CGRectMake(accuracyCenter.x-circleRadius,
								   accuracyCenter.y-circleRadius,
								   circleRadius*2,
								   circleRadius*2);
	
	// Calculate the map rect that the circle will cover, and then decide if that
	//	overlaps the region of the map being drawn.
	MKMapRect coverageMapRect = [self mapRectForRect:minRect];
	
	if (!MKMapRectIntersectsRect(coverageMapRect,mapRect) && !MKMapRectIntersectsRect(accuracyMapRect,mapRect))
		return;		// nothing this renderer draws overlaps the region being
	
	CGPathRef minPath = CGPathCreateWithEllipseInRect(minRect,NULL);
	
	if (minRect.size.width>=accuracyRect.size.width)
		{
		// The accuracy area is smaller than the minimum circle
		// Fill with a solid color value, the color of which indicates the accuracy of the location
		CGFloat accuracy = 1.0-(accuracyRect.size.width/minRect.size.width);
		CGContextSetRGBFillColor(context,AccuracyFillRGBA(accuracy));
		CGContextAddPath(context,minPath);
		CGContextFillPath(context);
		}
	else
		{
		// The accuracy circle is larger than the minimum circle
		// Draw a gradient indicating the accuracy area
		CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[] =
			{
			kInaccurateInnerColorRGBA,
			kInaccurateOuterColorRGBA
			};
		CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb,colors,NULL,2);
		CGPathRef accuracyPath = CGPathCreateWithEllipseInRect(accuracyRect,NULL);

		CGContextSaveGState(context);
		CGContextAddPath(context,accuracyPath);
		CGContextClip(context);
		CGContextDrawRadialGradient(context,gradient,
									accuracyCenter,0,
									accuracyCenter,accuracyRect.size.width/2,
									0);
		CGContextRestoreGState(context);
		
		CGPathRelease(accuracyPath);
		CGGradientRelease(gradient);
		CGColorSpaceRelease(rgb);
		}
}

@end
