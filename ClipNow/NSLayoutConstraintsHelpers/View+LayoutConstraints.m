//
//  NSView+LayoutConstraints.m
//
//  Created by Vlad on 2/2/15.
//
//

#import "View+LayoutConstraints.h"

@implementation View (LayoutConstraints)

- (nullable NSException*)addConstraints:(NSArray*)strings views:(NSDictionary*)views metrics:(NSDictionary*)metrics {
    @try {
        NSArray *constraints = [NSLayoutConstraint constraintsWithStrings:strings views:views metrics:metrics];
        [NSLayoutConstraint activateConstraints:constraints];
    }
    @catch (NSException *exception) {
        return exception;
    }
    
    return nil;
}

- (nullable NSException*)addConstraints:(NSArray*)strings views:(NSDictionary*)views {
    return [self addConstraints:strings views:views metrics:nil];
}

- (void)removeAllConstraints {
    for (NSLayoutConstraint *constraint in self.constraints) {
        constraint.active = NO;
    }
}

#pragma mark - Needs superview

- (BOOL)addConstraintsWithEdgeInsets:(EdgeInsets)insets {
    if (!self.superview) {
        return NO;
    }
    
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithEdgeInsets:insets onView:self]];
    return YES;
}

- (BOOL)addConstraintCenterVertically {
    return [self addConstraintCenterVerticallyWithConstant:0.0];
}

- (BOOL)addConstraintCenterVerticallyWithConstant:(CGFloat)constant {
    return [self addConstraintCenterVerticallyWithMultiplier:1 constant:constant];
}

- (BOOL)addConstraintCenterVerticallyWithMultiplier:(CGFloat)multiplier {
    return [self addConstraintCenterVerticallyWithMultiplier:multiplier constant:0];
}

- (BOOL)addConstraintCenterVerticallyWithMultiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    if (!self.superview) {
        return NO;
    }
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeCenterY multiplier:multiplier constant:constant];
    [self.superview addConstraint:constraint];
    return YES;
}

- (BOOL)addConstraintCenterHorizontally {
    if (!self.superview) {
        return NO;
    }
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [self.superview addConstraint:constraint];
    return YES;
}

- (BOOL)addHeightConstraint:(CGFloat)height {
    if (!self.superview) {
        return NO;
    }
    [self.superview addConstraint:[NSLayoutConstraint heightConstraint:height onView:self]];
    return YES;
}

- (BOOL)addWidthConstraint:(CGFloat)width {
    if (!self.superview) {
        return NO;
    }
    [self.superview addConstraint:[NSLayoutConstraint widthConstraint:width onView:self]];
    return YES;
}

- (BOOL)addSizeConstraints:(Size)size {
    return [self addHeightConstraint:size.height] && [self addWidthConstraint:size.width];
}

- (BOOL)addSuperviewSizedConstraints {
    return [self addConstraintsWithEdgeInsets:EdgeInsetsMake(0, 0, 0, 0)];
}

- (BOOL)addConstraintEqualWidth {
    return [self addConstraintEqualWidth:1];
}

- (BOOL)addConstraintEqualWidth:(CGFloat)multiplier {
    if (!self.superview) {
        return NO;
    }
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeWidth multiplier:multiplier constant:0]];
    return YES;
}

- (BOOL)addConstraintEqualHeight {
    return [self addConstraintEqualHeightWithMultiplier:1];
}

- (BOOL)addConstraintEqualHeightWithMultiplier:(CGFloat)multiplier {
    return [self addConstraintEqualHeightWithMultiplier:multiplier constant:0];
}

- (BOOL)addConstraintEqualHeightWithConstant:(CGFloat)constant {
    return [self addConstraintEqualHeightWithMultiplier:1 constant:constant];
}

- (BOOL)addConstraintEqualHeightWithMultiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    if (!self.superview) {
        return NO;
    }
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.superview attribute:NSLayoutAttributeHeight multiplier:multiplier constant:constant]];
    return YES;
}

@end
