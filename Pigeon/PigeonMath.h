//
//  PigeonMath.h
//  Pigeon
//
//  Created by James Bucanek on 12/15/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#ifndef Pigeon_PigeonMath_h
#define Pigeon_PigeonMath_h

//
// Some handy math routines as macros
//

#if CGFLOAT_IS_DOUBLE
// On a 64-bit CPU, CGFloat is a double; use double math functions
#define CGAbs		fabs
#define CGMax		fmax
#define CGMin		fmin
#define CGCeiling	ceil
#define CGFloor		floor
#define CGRound		round
#define CGHypot		hypot
#define CGSin		sin
#define	CGCos		cos
#define CGATan2		atan2
#else
// On a 32-bit CPU, CGFloat is a float; use float math functions
#define CGAbs		fabsf
#define CGMax		fmaxf
#define CGMin		fminf
#define CGCeiling	ceilf
#define CGFloor		floorf
#define CGRound		roundf
#define CGHypot		hypotf
#define CGSin		sinf
#define	CGCos		cosf
#define CGATan2		atan2f
#endif

// Return the center point of a rectangle
// Note: RECT should not be an expression, or it will be evaluated twice
#define CenterOfRect(RECT) CGPointMake(CGRectGetMidX(RECT),CGRectGetMidY(RECT))

// Compare two map coordiantes for equality
#define CoordinatesEqual(A,B) (A.longitude==B.longitude && A.latitude==B.latitude)

#endif
