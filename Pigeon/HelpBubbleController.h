//
//  HelpBubbleController.h
//  Pigeon
//
//  Created by James Bucanek on 2/4/14.
//  Copyright (c) 2014 Dawn to Dusk Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HelpBubbleView;


@interface HelpBubbleController : NSObject

- (id)initWithNib:(NSString*)nibName;

@property (weak,nonatomic) id delegate;

@property (strong,nonatomic) IBOutlet HelpBubbleView* bubbleView;

- (void)presentForView:(UIView*)targetView fromView:(UIView*)originView;
- (void)dismiss;
- (void)retract;

@end
