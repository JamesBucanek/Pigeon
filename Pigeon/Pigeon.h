//
//  Pigeon.h
//  Pigeon
//
//  Created by James Bucanek on 12/24/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#ifndef Pigeon_Pigeon_h
#define Pigeon_Pigeon_h

#if 1	// 1==Production: Disable _all_ TESTLog statements
		// 0==Development: Enable/Disable individually per module
	#ifndef NO_TEST_LOG
	#define NO_TEST_LOG
	#endif
#endif

#ifndef NO_TEST_LOG
#define TESTLog(FORMAT,...) NSLog(@"%s " FORMAT,__func__,__VA_ARGS__)
#else
#define TESTLog(...)
#endif

// CLAMP macro
// Equivalent to MIN(MAX(v,min),max), but just a tad more efficient and easier to read
#ifndef CLAMP
#define CLAMP(V,L,H)	({	__typeof__(V) __v = (V); \
							__typeof__(L) __min = (L); \
							__v<__min ? __min : \
								({ __typeof__(H) __max = (H); __v>__max ? __max : __v; }); \
						})
// TODO: SAFECLAMP(V,L,H) that returns L if H<L
#endif

// UNITRANGE(v,min,max) returns the relative linear distance of v between min and max.
// That is, returns 0.0 if v==min, returns 1.0 if v==max.
#ifndef UNITRANGE
#define UNITRANGE(V,L,H)	({	__typeof__(L) __min = (L); \
								((V)-__min)/((H)-__min); \
							})
#endif

// CLAMPEDUNITRANGE(v,min,max) is the same as UNITRANGE, but the returned value is
//	clamped between 0 and 1 (inclusive).
#ifndef CLAMPEDUNITRANGE
#define CLAMPEDUNITRANGE(V,L,H)	({	__typeof__(V) __v = (V); \
									__typeof__(L) __min = (L); \
									( __v<=__min ? (__typeof__(V))0 : \
										({	__typeof__(H) __max = (H); \
											(__v>=__max ? (__typeof__(V))1 : \
														  (__v-__min)/(__max-__min)); }) \
									); \
								})
#endif

// TORANGE(unit,min,max) converts a unit value (0...1) into a value within a range (min...max).
// The inverse function of UNITRANGE()
#ifndef TORANGE
#define TORANGE(U,L,H)	({	__typeof__(L) __min = (L); \
							((U)*((H)-__min)+__min); \
						})
#endif

// TRANSPOSERANGE(v,fromMin,fromMax,toMin,toMax) Transposes a value within a range (fromMin...fromMax)
//	to the corresponding value in the destination range (toMin...toMax).
// Equivelent to TORANGE(UNITRANGE(v,fromMin,fromMax),toMin,toMax)
#ifndef TRANSPOSERANGE
#define TRANSPOSERANGE(V,FL,FH,TL,TH)	({	__typeof__(FL) __fromMin = (FL); \
											__typeof__(TL) __toMin = (TL); \
											(((V)-__fromMin)/((FH)-__fromMin))*((TH)-__toMin)+__toMin; \
										})
#endif

// Smart equality macros

// OBJECTS_EQUAL uses -[NSObject isEqual:] to determine the equality of two objects, but intellegently
//	handles the identity case (a==b) as well as either object pointer being nil.
#ifndef OBJECTS_EQUAL
#define OBJECTS_EQUAL(A,B) ({	id __a = (A); id __b = (B); \
								( __a==__b || ( __b!=nil && [__a isEqual:__b] ) ); \
							})
// STRINGS_EQUAL is the same as OBJECTS_EQUAL, except that it uses NSStrings and -isEqualToString:
#define STRINGS_EQUAL(A,B) ({	NSString* __a = (A); NSString* __b = (B); \
								( __a==__b || ( __b!=nil && [__a isEqualToString:__b] ) ); \
							})
// DATES_EQUAL is the same as OBJECTS_EQUAL, except that it uses NSDates and -isEqualToDate:
#define DATES_EQUAL(A,B)   ({	NSDate* __a = (A); NSDate* __b = (B); \
							( __a==__b || ( __b!=nil && [__a isEqualToDate:__b] ) ); \
							})
#endif


#endif
