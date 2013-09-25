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

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)title color:(UIColor *)color font:(UIFont *)aFont tag:(NSInteger)tag handler:(SIAlertViewHandler)handler
{
    SIAlertButton *button = [SIAlertButton buttonWithType:UIButtonTypeCustom];
	[button setTitle:title forState:UIControlStateNormal];
    button.color = color;
	button.tag = tag;
    button.handler = handler;
    button.titleLabel.font = aFont;

    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    return button;
}

#pragma mark - Setters

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

#pragma mark - UIButton

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
