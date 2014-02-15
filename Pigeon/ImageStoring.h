//
//  ImageStoring.h
//  Pigeon
//
//  Created by James Bucanek on 1/4/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import <Foundation/Foundation.h>

// A protocol that defines the interface for managing a set of pictures attached
//	to a location/document.

@protocol ImageStoring <NSObject>

@property (readonly,nonatomic) NSUInteger pictureCount;
@property (readonly,nonatomic) NSArray* pictures;
- (UIImage*)pictureAtIndex:(NSUInteger)index;
- (UIImage*)thumbnailFittingSize:(CGSize)size forPictureAtIndex:(NSUInteger)index;
- (void)addPicture:(UIImage*)image;
- (void)removePictureAtIndex:(NSUInteger)index;

@end
