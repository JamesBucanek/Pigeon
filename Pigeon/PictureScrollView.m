//
//  PictureScrollView.m
//  Pigeon
//
//  Created by James Bucanek on 12/28/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import "PictureScrollView.h"

//#define NO_TEST_LOG
#import "Pigeon.h"
#import "PigeonMath.h"


@interface PictureScrollView () // private
@end


@implementation PictureScrollView

- (void)awakeFromNib
{
	self.delegate = self;
}

#pragma mark Properties

- (UIImage*)image
{
	return _imageView.image;
}

- (void)setImage:(UIImage *)image
{
	self.zoomScale = 1.0;
	_imageView.image = image;
}

#pragma mark Layout

- (CGFloat)minimumZoomScaleForImageSize:(CGSize)imageSize
{
	// Calculate the min zoom scale that will allow an image, larger than the view,
	//	to exactly fit in the view.
	// Clips the zoom scale to 1.0, so it won't return a scale greater than 1.0
	//	if the image is smaller than the view.
	CGFloat minZoom = 1.0;
	CGSize displaySize = self.bounds.size;
	if (displaySize.height!=0.0 && displaySize.width!=0)
		{
		CGFloat vZoom = displaySize.height/imageSize.height;
		CGFloat hZoom = displaySize.width/imageSize.width;
		minZoom = CGMin(CGMin(vZoom,hZoom),(CGFloat)1.0);
		}
	return minZoom;
}

#pragma mark <UIScrollViewDelegate>

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _imageView;
}

@end
