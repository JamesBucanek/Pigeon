//
//  PictureScrollView.h
//  Pigeon
//
//  Created by James Bucanek on 12/28/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

//
// A pinch-zoomable scroll view container for the picture.
//

@interface PictureScrollView : UIScrollView <UIScrollViewDelegate>

@property (weak,nonatomic) UIImage* image;

@property (weak,nonatomic) IBOutlet UIImageView* imageView;

- (CGFloat)minimumZoomScaleForImageSize:(CGSize)imageSize;

@end
