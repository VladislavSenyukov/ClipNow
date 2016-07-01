//
//  NSView+LayoutConstraints.h
//
//  Created by Vlad on 2/2/15.
//
//

#import "NSLayoutConstraint+Additions.h"

@interface View (LayoutConstraints)

//*
- (NSException*)addConstraints:(NSArray*)strings views:(NSDictionary*)views metrics:(NSDictionary*)metrics;
- (NSException*)addConstraints:(NSArray*)strings views:(NSDictionary*)views;

- (void)removeAllConstraints;

// should have a superview
- (BOOL)addConstraintsWithEdgeInsets:(EdgeInsets)insets;
- (BOOL)addHeightConstraint:(CGFloat)height;
- (BOOL)addWidthConstraint:(CGFloat)width;
- (BOOL)addSizeConstraints:(Size)size;
- (BOOL)addConstraintCenterVertically;
- (BOOL)addConstraintCenterVerticallyWithConstant:(CGFloat)constant;
- (BOOL)addConstraintCenterVerticallyWithMultiplier:(CGFloat)multiplier;
- (BOOL)addConstraintCenterHorizontally;
- (BOOL)addSuperviewSizedConstraints;
- (BOOL)addConstraintEqualWidth;
- (BOOL)addConstraintEqualWidth:(CGFloat)multiplier;
- (BOOL)addConstraintEqualHeight;
- (BOOL)addConstraintEqualHeightWithMultiplier:(CGFloat)multiplier;
- (BOOL)addConstraintEqualHeightWithConstant:(CGFloat)constant;
- (BOOL)addConstraintEqualHeightWithMultiplier:(CGFloat)multiplier
                                      constant:(CGFloat)constant;

@end
