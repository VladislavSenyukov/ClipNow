//
//  NSLayoutConstraint+Additions.h
//
//  Created by Vlad on 2/2/15.
//
//

#import "TargetConditionals.h"

#if TARGET_OS_IOS

@import UIKit;
#define View            UIView
#define EdgeInsets      UIEdgeInsets
#define Size            CGSize
#define EdgeInsetsMake(t, l, b, r)        UIEdgeInsetsMake(t, l, b, r)

#else

@import Cocoa;
#define View            NSView
#define EdgeInsets      NSEdgeInsets
#define Size            NSSize
#define EdgeInsetsMake(t, l, b, r)        NSEdgeInsetsMake(t, l, b, r)

#endif


@interface NSLayoutConstraint (Additions)

/**
 *  Constraints for an array of strings with visual format language
 */
+ (NSArray*)constraintsWithStrings:(NSArray*)strings
                             views:(NSDictionary*)views
                           metrics:(NSDictionary*)metrics;

/**
 *  Constraint for a single string. If the string imply more than 1 constraint, a first constraint taken will be returned
 */
+ (NSLayoutConstraint*)constraintWithString:(NSString*)string
                                      views:(NSDictionary*)views
                                    metrics:(NSDictionary*)metrics;

+ (NSLayoutConstraint*)constraintWithString:(NSString*)string
                                      views:(NSDictionary*)views;

+ (NSArray*)constraintsWithStrings:(NSArray*)strings views:(NSDictionary*)views;
+ (NSArray *)constraintsWithEdgeInsets:(UIEdgeInsets)insets onView:(View*)view;
+ (NSLayoutConstraint*)heightConstraint:(CGFloat)height onView:(View*)view;
+ (NSLayoutConstraint*)widthConstraint:(CGFloat)width onView:(View *)view;

@end
