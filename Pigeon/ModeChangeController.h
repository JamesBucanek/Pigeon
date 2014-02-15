//
//  ModeChangeController
//  Pigeon
//
//  Created by James Bucanek on 12/18/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>

@class RoundedRectView;

//
// A helper controller that displays and animates a change in one
//	of the map modes. The modes to display are contained
//	in a NIB file, specified when the controller is initialized.
//

@interface ModeChangeController : NSObject

- (id)initWithName:(NSString*)name;

@property (nonatomic) CGFloat							cornerRadius;
@property (nonatomic) CGFloat							lineWidth;
@property (strong,nonatomic) UIColor*					strokeColor;
@property (strong,nonatomic) UIColor*					fillColor;

@property (strong,nonatomic) IBOutlet UIView*			view;
@property (nonatomic) NSUInteger						optionCount;

- (void)animateSwitchFrom:(NSUInteger)fromIndex
					   to:(NSUInteger)toIndex
				   inView:(UIView*)parentView
			   centeredAt:(CGPoint)center;

@end
