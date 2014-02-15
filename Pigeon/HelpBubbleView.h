//
//  HelpBubbleView.h
//  Pigeon
//
//  Created by James Bucanek on 2/4/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RoundedRectView.h"

//
// A rounded rect view with a triangle on one edge used to
//	point to something.
//


@interface HelpBubbleView : RoundedRectView

@property (nonatomic) NSUInteger pointerEdge;
@property (nonatomic) CGFloat pointerLength;
@property (nonatomic) CGFloat pointOffset;

@property (readonly,nonatomic) CGPoint pointPoint;
+ (CGPoint)pointOnEdge:(CGRectEdge)edge ofView:(UIView*)view withOffset:(CGFloat)offset;
- (CGRect)framePointingAt:(CGPoint)point;

@end
