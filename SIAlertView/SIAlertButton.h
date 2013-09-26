//
//  SIAlertButton.h
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIAlertView.h"

typedef NS_ENUM (NSInteger, SIAlertButtonColor) {
    SIAlertButtonColorDefault,
    SIAlertButtonColorPrimary,
    SIAlertButtonColorInfo,
    SIAlertButtonColorSuccess,
    SIAlertButtonColorWarning,
    SIAlertButtonColorDanger,
    SIAlertButtonColorInverse,
    SIAlertButtonColorTwitter,
    SIAlertButtonColorFacebook,
    SIAlertButtonColorPurple,
    SIAlertButtonColorCancel
};

@interface SIAlertButton : UIButton

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, copy) SIAlertViewHandler handler;

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)title color:(UIColor *)color font:(UIFont *)font tag:(NSInteger)tag handler:(SIAlertViewHandler)handler;
+ (UIColor *)colorForSIAlertButtonColor:(SIAlertButtonColor)colorType;

@end
