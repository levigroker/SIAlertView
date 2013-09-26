//
//  SIAlertButton.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertButton.h"
#import "UIColor+SIAlertView.h"

@implementation SIAlertButton

#pragma mark - Initialization

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)title color:(UIColor *)color font:(UIFont *)font tag:(NSInteger)tag handler:(SIAlertViewHandler)handler
{
    SIAlertButton *button = [SIAlertButton buttonWithType:UIButtonTypeCustom];
	[button setTitle:title forState:UIControlStateNormal];
    button.color = color;
	button.tag = tag;
    button.handler = handler;
    button.titleLabel.font = font;

    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    return button;
}

#pragma mark - Class Level

+ (UIColor *)colorForSIAlertButtonColor:(SIAlertButtonColor)colorType
{
    switch (colorType) {
        case SIAlertButtonColorPrimary:
            return [UIColor colorWithHue:215.0f/360.0f saturation:0.82f brightness:0.84f alpha:1.0f];
            
        case SIAlertButtonColorInfo:
            return [UIColor colorWithHue:194.0f/360.0f saturation:0.75f brightness:0.74f alpha:1.0f];
            
        case SIAlertButtonColorSuccess:
            return [UIColor colorWithHue:116.0f/360.0f saturation:0.5f brightness:0.74f alpha:1.0f];
            
        case SIAlertButtonColorWarning:
            return [UIColor colorWithHue:35.0f/360.0f saturation:0.90f brightness:0.96f alpha:1.0f];
            
        case SIAlertButtonColorDanger:
            return [UIColor colorWithHue:3.0f/360.0f saturation:0.76f brightness:0.88f alpha:1.0f];
            
        case SIAlertButtonColorInverse:
            return [UIColor colorWithHue:0.0f saturation:0.0f brightness:0.2f alpha:1.0f];
            
        case SIAlertButtonColorTwitter:
            return [UIColor colorWithHue:212.0f/360.0f saturation:0.75f brightness:1.0f alpha:1.0f];
            
        case SIAlertButtonColorFacebook:
            return [UIColor colorWithHue:220.0f/360.0f saturation:0.62f brightness:0.6f alpha:1.0f];
            
        case SIAlertButtonColorPurple:
            return [UIColor colorWithHue:260.0f/360.0f saturation:0.45f brightness:0.75f alpha:1.0f];
            
        case SIAlertButtonColorCancel:
            return [UIColor colorWithHue:0.0f saturation:0.0f brightness:0.7f alpha:1.0f];
            
        case SIAlertButtonColorDefault:
        default:
            return [UIColor colorWithHue:0.0f saturation:0.0f brightness:0.94f alpha:1.0f];
    }
}

#pragma mark - Accessors

- (void)setColor:(UIColor *)newColor
{
    _color = newColor;
    
    if ([newColor isLightColor]) {
        [self setTitleColor:[UIColor colorWithWhite:0.35f alpha:1.0f] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithWhite:0.35f alpha:0.8f] forState:UIControlStateHighlighted];
    }
    else {
        [self setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.8f] forState:UIControlStateHighlighted];
    }
    
    [self setNeedsDisplay];
}

#pragma mark - UIButton Overrides

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    UIColor *fill = (!self.highlighted) ? self.color : [self.color darkenColorWithValue:0.06f];
    CGContextSetFillColorWithColor(context, fill.CGColor);
    
    UIColor *border = (!self.highlighted) ? [self.color darkenColorWithValue:0.06f] : [self.color darkenColorWithValue:0.12f];
    CGContextSetStrokeColorWithColor(context, border.CGColor);
    
    CGContextSetLineWidth(context, 1.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, rect.size.width-1.0f, rect.size.height-1.0f)
                                                    cornerRadius:3.5f];
    
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextRestoreGState(context);
}

@end
