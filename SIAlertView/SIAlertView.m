//
//  SIAlertView.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SIAlertView.h"
#import "SIAlertButton.h"
@class SIAlertBackgroundWindow;

NSString * const SIAlertViewWillShowNotification = @"SIAlertViewWillShowNotification";
NSString * const SIAlertViewDidShowNotification = @"SIAlertViewDidShowNotification";
NSString * const SIAlertViewWillDismissNotification = @"SIAlertViewWillDismissNotification";
NSString * const SIAlertViewDidDismissNotification = @"SIAlertViewDidDismissNotification";

#define DEBUG_LAYOUT 0

#define MESSAGE_MIN_LINE_COUNT 3
#define MESSAGE_MAX_LINE_COUNT 5
#define GAP 10
#define CANCEL_BUTTON_PADDING_TOP 5
#define CONTENT_PADDING_LEFT 10
#define CONTENT_PADDING_TOP 12
#define CONTENT_PADDING_BOTTOM 10
#define BUTTON_HEIGHT 44
#define CONTAINER_WIDTH 300

const UIWindowLevel UIWindowLevelSIAlert = 1999.0;  // don't overlap system's alert
const UIWindowLevel UIWindowLevelSIAlertBackground = 1998.0; // below the UIWindowLevelSIAlert


static NSMutableArray *__si_alert_queue;
static BOOL __si_alert_animating;
static SIAlertBackgroundWindow *__si_alert_background_window;
static SIAlertView *__si_alert_current_view;

#pragma mark - SIAlertView Interface

@interface SIAlertView ()

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIWindow *oldKeyWindow;
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, assign) BOOL visible;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign) BOOL layoutDirty;

- (void)setup;
- (void)invalidateLayout;
- (void)resetTransition;

@end

#pragma mark - SIAlertItem

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, copy) SIAlertViewHandler handler;

@end

@implementation SIAlertItem

@end

#pragma mark - SIAlertViewController

@interface SIAlertViewController : UIViewController

@property (nonatomic, strong) SIAlertView *alertView;
#ifdef __IPHONE_7_0
@property (nonatomic, assign) BOOL statusBarHidden;
#endif

@end

@implementation SIAlertViewController

#pragma mark - Lifecycle

- (void)loadView
{
    self.view = self.alertView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.alertView setup];
}

#pragma mark - Accessors

#ifdef __IPHONE_7_0
- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}
#endif

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    static Float32 angle = 90.0f * M_PI / 180.0f;
    Float32 rotationAngle = 0.0f;
    
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotationAngle = -angle;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotationAngle = angle;
            break;
        default:
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    //Handle the rotation
    if (rotationAngle != 0 || !CGAffineTransformIsIdentity(self.view.transform))
    {
        transform = CGAffineTransformMakeRotation(rotationAngle);
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.view.transform = transform;
    }];

    [UIView setAnimationsEnabled:NO];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.alertView resetTransition];
    [self.alertView invalidateLayout];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - Status Bar Handling

#ifdef __IPHONE_7_0
- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}
#endif

@end

#pragma mark - SIAlertBackgroundWindow

@interface SIAlertBackgroundWindow : UIWindow

@property (nonatomic, assign) SIAlertViewBackgroundStyle style;
- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style;

@end

@implementation SIAlertBackgroundWindow

- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        self.style = style;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelSIAlertBackground;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (self.style) {
        case SIAlertViewBackgroundStyleGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            break;
        }
        case SIAlertViewBackgroundStyleSolid:
        {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
    }
}

@end

#pragma mark - SIAlertView Implementation

@implementation SIAlertView

+ (void)initialize
{
    if (self != [SIAlertView class])
        return;

    SIAlertView *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor blackColor];
    appearance.messageColor = [UIColor darkGrayColor];
    appearance.titleFont = [UIFont boldSystemFontOfSize:20];
    appearance.messageFont = [UIFont systemFontOfSize:16];
    appearance.buttonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    appearance.buttonColor = [SIAlertButton colorForSIAlertButtonColor:SIAlertButtonColorDefault];
    appearance.cancelButtonColor = [SIAlertButton colorForSIAlertButtonColor:SIAlertButtonColorCancel];
    appearance.destructiveButtonColor = [SIAlertButton colorForSIAlertButtonColor:SIAlertButtonColorDanger];
    appearance.cornerRadius = 2;
    appearance.shadowRadius = 8;
}

- (id)init
{
	return [self initWithTitle:nil message:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
	self = [super init];
	if (self) {
		self.title = title;
        self.message = message;
        self.parallaxEnabled = YES;
		self.items = [[NSMutableArray alloc] init];
        //Initalize to our appearance defaults (iOS 7 doesn't yet handle appearance fully)
        SIAlertView *appearance = [SIAlertView appearance];
        self.viewBackgroundColor = appearance.viewBackgroundColor;
        self.titleColor = appearance.titleColor;
        self.messageColor = appearance.messageColor;
        self.titleFont = appearance.titleFont;
        self.messageFont = appearance.messageFont;
        self.buttonFont = appearance.buttonFont;
        self.buttonColor = appearance.buttonColor;
        self.cancelButtonColor = appearance.cancelButtonColor;
        self.destructiveButtonColor = appearance.destructiveButtonColor;
        self.cornerRadius = appearance.cornerRadius;
        self.shadowRadius = appearance.shadowRadius;
	}
	return self;
}

#pragma mark - Class methods

+ (NSMutableArray *)sharedQueue
{
    if (!__si_alert_queue) {
        __si_alert_queue = [NSMutableArray array];
    }
    return __si_alert_queue;
}

+ (SIAlertView *)currentAlertView
{
    return __si_alert_current_view;
}

+ (void)setCurrentAlertView:(SIAlertView *)alertView
{
    __si_alert_current_view = alertView;
}

+ (BOOL)animating
{
    return __si_alert_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __si_alert_animating = animating;
}

+ (void)showBackground
{
    if (!__si_alert_background_window) {
        __si_alert_background_window = [[SIAlertBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                             andStyle:[SIAlertView currentAlertView].backgroundStyle];
        [__si_alert_background_window makeKeyAndVisible];
        __si_alert_background_window.alpha = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             __si_alert_background_window.alpha = 1;
                         }];
    }
}

+ (void)hideBackgroundAnimated:(BOOL)animated
{
    if (!animated) {
        [__si_alert_background_window removeFromSuperview];
        __si_alert_background_window = nil;
        return;
    }
    [UIView animateWithDuration:0.3
                     animations:^{
                         __si_alert_background_window.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [__si_alert_background_window removeFromSuperview];
                         __si_alert_background_window = nil;
                     }];
}

#pragma mark - Accessors

- (void)setTitle:(NSString *)title
{
    _title = title;
	[self invalidateLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    [self invalidateLayout];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title
{
    [self addButtonWithTitle:title type:SIAlertViewButtonTypeDefault handler:nil];
}

- (void)addButtonWithTitle:(NSString *)title handler:(SIAlertViewHandler)handler
{
    [self addButtonWithTitle:title type:SIAlertViewButtonTypeDefault handler:handler];
}

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
	UIColor *color = [self colorForButtonType:type];
    [self addButtonWithTitle:title type:type color:color handler:handler];
}

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type color:(UIColor *)color handler:(SIAlertViewHandler)handler
{
    SIAlertItem *item = [[SIAlertItem alloc] init];
	item.title = title;
	item.type = type;
	item.color = color;
	item.handler = handler;
	[self.items addObject:item];
}

- (void)show
{
    self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];

    if (![[SIAlertView sharedQueue] containsObject:self]) {
        [[SIAlertView sharedQueue] addObject:self];
    }

    if ([SIAlertView animating]) {
        return; // wait for next turn
    }

    if (self.visible) {
        return;
    }

    if ([SIAlertView currentAlertView].visible) {
        SIAlertView *alert = [SIAlertView currentAlertView];
        [alert dismissAnimated:YES cleanup:NO];
        return;
    }

    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillShowNotification object:self userInfo:nil];

    self.visible = YES;

    [SIAlertView setAnimating:YES];
    [SIAlertView setCurrentAlertView:self];

    // transition background
    [SIAlertView showBackground];

    SIAlertViewController *viewController = [[SIAlertViewController alloc] initWithNibName:nil bundle:nil];
    viewController.alertView = self;
    #ifdef __IPHONE_7_0
    viewController.statusBarHidden = self.statusBarHidden;
    #endif

    if (!self.alertWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelSIAlert;
        window.rootViewController = viewController;
        self.alertWindow = window;
    }
    [self.alertWindow makeKeyAndVisible];

    [self validateLayout];

    [self transitionInCompletion:^{
        if (self.didShowHandler) {
            self.didShowHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidShowNotification object:self userInfo:nil];
        #ifdef __IPHONE_7_0
        [self addParallaxEffect];
        #endif

        [SIAlertView setAnimating:NO];

        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index < [SIAlertView sharedQueue].count - 1) {
            [self dismissAnimated:YES cleanup:NO]; // dismiss to show next alert view
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated cleanup:YES];
}

- (void)dismissAnimated:(BOOL)animated cleanup:(BOOL)cleanup
{
    BOOL visible = self.visible;

    if (visible) {
        if (self.willDismissHandler) {
            self.willDismissHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillDismissNotification object:self userInfo:nil];
        #ifdef __IPHONE_7_0
                [self removeParallaxEffect];
        #endif
    }

    void (^dismissComplete)(void) = ^{
        self.visible = NO;

        [self teardown];

        [SIAlertView setCurrentAlertView:nil];

        SIAlertView *nextAlertView;
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index != NSNotFound && index < [SIAlertView sharedQueue].count - 1) {
            nextAlertView = [SIAlertView sharedQueue][index + 1];
        }

        if (cleanup) {
            [[SIAlertView sharedQueue] removeObject:self];
        }

        [SIAlertView setAnimating:NO];

        if (visible) {
            if (self.didDismissHandler) {
                self.didDismissHandler(self);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidDismissNotification object:self userInfo:nil];
        }

        // check if we should show next alert
        if (!visible) {
            return;
        }

        if (nextAlertView) {
            [nextAlertView show];
        } else {
            // show last alert view
            if ([SIAlertView sharedQueue].count > 0) {
                SIAlertView *alert = [[SIAlertView sharedQueue] lastObject];
                [alert show];
            }
        }
    };

    if (animated && visible) {
        [SIAlertView setAnimating:YES];
        [self transitionOutCompletion:dismissComplete];

        if ([SIAlertView sharedQueue].count == 1) {
            [SIAlertView hideBackgroundAnimated:YES];
        }

    } else {
        dismissComplete();

        if ([SIAlertView sharedQueue].count == 0) {
            [SIAlertView hideBackgroundAnimated:YES];
        }
    }

    [self.oldKeyWindow makeKeyWindow];
    self.oldKeyWindow.hidden = NO;
}

#pragma mark - Transitions

- (void)transitionInCompletion:(void(^)(void))completion
{
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = self.bounds.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = -rect.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleFade:
        {
            self.containerView.alpha = 0;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(0.01), @(1.2), @(0.9), @(1)];
            animation.keyTimes = @[@(0), @(0.4), @(0.6), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.5;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bouce"];
            break;
        }
        case SIAlertViewTransitionStyleDropDown:
        {
            CGFloat y = self.containerView.center.y;
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
            animation.values = @[@(y - self.bounds.size.height), @(y + 20), @(y - 10), @(y)];
            animation.keyTimes = @[@(0), @(0.5), @(0.75), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.4;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"dropdown"];
            break;
        }
        default:
            break;
    }
}

- (void)transitionOutCompletion:(void(^)(void))completion
{
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = -rect.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleFade:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 self.containerView.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(1), @(1.2), @(0.01)];
            animation.keyTimes = @[@(0), @(0.4), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.35;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bounce"];

            self.containerView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            break;
        }
        case SIAlertViewTransitionStyleDropDown:
        {
            CGPoint point = self.containerView.center;
            point.y += self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.center = point;
                                 CGFloat angle = ((CGFloat)arc4random_uniform(100) - 50.f) / 100.f;
                                 self.containerView.transform = CGAffineTransformMakeRotation(angle);
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
            break;
        }
        default:
            break;
    }
}

- (void)resetTransition
{
    [self.containerView.layer removeAllAnimations];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self validateLayout];
}

- (void)invalidateLayout
{
    self.layoutDirty = YES;
    [self setNeedsLayout];
}

- (void)validateLayout
{
    if (!self.layoutDirty) {
        return;
    }
    self.layoutDirty = NO;
#if DEBUG_LAYOUT
    NSLog(@"%@, %@", self, NSStringFromSelector(_cmd));
#endif

    CGFloat height = [self preferredHeight];
    CGFloat left = (self.bounds.size.width - CONTAINER_WIDTH) * 0.5;
    CGFloat top = (self.bounds.size.height - height) * 0.5;
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.frame = CGRectMake(left, top, CONTAINER_WIDTH, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;

    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel) {
        self.titleLabel.text = self.title;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
	}

    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageLabel.text = self.message;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }

    if (self.items.count > 0) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }

        if (self.items.count == 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            CGFloat width = (self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
            UIButton *button = self.buttons[0];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
            button = self.buttons[1];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
        }
        else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);

                if (self.buttons.count > 1) {
                    if (i == self.buttons.count - 1 && ((SIAlertItem *)self.items[i]).type == SIAlertViewButtonTypeCancel) {
                        CGRect rect = button.frame;
                        rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                        button.frame = rect;
                    }
                    y += BUTTON_HEIGHT + GAP;
                }
            }
        }
    }
}

- (CGFloat)preferredHeight
{
	CGFloat height = CONTENT_PADDING_TOP;
	if (self.title) {
		height += [self heightForTitleLabel];
	}

    if (self.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageLabel];
    }

    if (self.items.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }

        if (self.items.count <= 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            height += BUTTON_HEIGHT;
        }
        else
        {
            height += (BUTTON_HEIGHT + GAP) * self.items.count - GAP;
            if (self.buttons.count > 2 && ((SIAlertItem *)[self.items lastObject]).type == SIAlertViewButtonTypeCancel) {
                height += CANCEL_BUTTON_PADDING_TOP;
            }
        }
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
        CGSize size = [self.title sizeWithFont:self.titleLabel.font
                                   minFontSize:self.titleLabel.font.pointSize * self.titleLabel.minimumScaleFactor
                                actualFontSize:nil
                                      forWidth:CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2
                                 lineBreakMode:self.titleLabel.lineBreakMode];
        return size.height;
    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
    CGFloat minHeight = MESSAGE_MIN_LINE_COUNT * self.messageLabel.font.lineHeight;
    if (self.messageLabel) {
        CGFloat maxHeight = MESSAGE_MAX_LINE_COUNT * self.messageLabel.font.lineHeight;
        CGSize size = [self.message sizeWithFont:self.messageLabel.font
                               constrainedToSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, maxHeight)
                                   lineBreakMode:self.messageLabel.lineBreakMode];
        return MAX(minHeight, size.height);
    }
    return minHeight;
}

#pragma mark - Setup

- (void)setup
{
    [self setupContainerView];
    [self updateTitleLabel];
    [self updateMessageLabel];
    [self setupButtons];
    [self invalidateLayout];
}

- (void)teardown
{
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    self.titleLabel = nil;
    self.messageLabel = nil;
    [self.buttons removeAllObjects];
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
    self.layoutDirty = NO;
}

- (void)setupContainerView
{
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = _viewBackgroundColor ? _viewBackgroundColor : [UIColor whiteColor];
    self.containerView.layer.cornerRadius = self.cornerRadius;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = 0.5;
    [self addSubview:self.containerView];
}

- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.titleFont;
            self.titleLabel.textColor = self.titleColor;
            self.titleLabel.adjustsFontSizeToFitWidth = YES;
            self.titleLabel.minimumScaleFactor = 0.75;
			[self.containerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.text = self.title;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
    [self invalidateLayout];
}

- (void)updateMessageLabel
{
    if (self.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.messageFont;
            self.messageLabel.textColor = self.messageColor;
            self.messageLabel.numberOfLines = MESSAGE_MAX_LINE_COUNT;
            [self.containerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.text = self.message;
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
    [self invalidateLayout];
}

- (void)setupButtons
{
    self.buttons = [[NSMutableArray alloc] initWithCapacity:self.items.count];
    for (NSUInteger i = 0; i < self.items.count; i++)
    {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self.containerView addSubview:button];
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    SIAlertItem *item = self.items[index];
    SIAlertButton *button = [SIAlertButton alertButtonWithTitle:item.title color:item.color font:self.buttonFont tag:index handler:item.handler];

	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIColor *)colorForButtonType:(SIAlertViewButtonType)type
{
    UIColor *retVal = nil;

	switch (type) {
		case SIAlertViewButtonTypeCancel:
            retVal = self.cancelButtonColor;
			break;
		case SIAlertViewButtonTypeDestructive:
            retVal = self.destructiveButtonColor;
			break;
		case SIAlertViewButtonTypeDefault:
		default:
            retVal = self.buttonColor;
			break;
	}

    return retVal;
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
	[SIAlertView setAnimating:YES]; // set this flag to YES in order to prevent showing another alert in hanlder block
    SIAlertItem *item = self.items[button.tag];
	if (item.handler) {
		item.handler(self);
	}
	[self dismissAnimated:YES];
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}

#pragma mark - UIAppearance setters

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    if (_viewBackgroundColor == viewBackgroundColor) {
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    self.containerView.backgroundColor = viewBackgroundColor;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
    [self invalidateLayout];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    if (_messageFont == messageFont) {
        return;
    }
    _messageFont = messageFont;
    self.messageLabel.font = messageFont;
    [self invalidateLayout];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (_messageColor == messageColor) {
        return;
    }
    _messageColor = messageColor;
    self.messageLabel.textColor = messageColor;
}

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UIButton *button in self.buttons) {
        button.titleLabel.font = buttonFont;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.containerView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    self.containerView.layer.shadowRadius = shadowRadius;
}

- (void)setButtonColor:(UIColor *)buttonColor
{
    if (_buttonColor == buttonColor) {
        return;
    }
    _buttonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeDefault];
}

- (void)setCancelButtonColor:(UIColor *)buttonColor
{
    if (_cancelButtonColor == buttonColor) {
        return;
    }
    _cancelButtonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeCancel];
}

- (void)setDestructiveButtonColor:(UIColor *)buttonColor
{
    if (_destructiveButtonColor == buttonColor) {
        return;
    }
    _destructiveButtonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeDestructive];
}

#pragma mark - Helpers

- (void)setColor:(UIColor *)color toButtonsOfType:(SIAlertViewButtonType)type
{
    for (NSUInteger i = 0; i < self.items.count; i++)
    {
        SIAlertItem *item = self.items[i];
        if (item.type == type)
        {
            SIAlertButton *button = self.buttons[i];
            button.color = color;
        }
    }
}

#ifdef __IPHONE_7_0

#pragma mark - Parallax effect

- (void)addParallaxEffect
{
    if (self.parallaxEnabled && NSClassFromString(@"UIInterpolatingMotionEffect"))
    {
        UIInterpolatingMotionEffect *effectHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"position.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        UIInterpolatingMotionEffect *effectVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"position.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        [effectHorizontal setMaximumRelativeValue:@(10.0f)];
        [effectHorizontal setMinimumRelativeValue:@(-10.0f)];
        [effectVertical setMaximumRelativeValue:@(20.0f)];
        [effectVertical setMinimumRelativeValue:@(-20.0f)];
        [self.containerView addMotionEffect:effectHorizontal];
        [self.containerView addMotionEffect:effectVertical];
    }
}

- (void)removeParallaxEffect
{
    if (self.parallaxEnabled && NSClassFromString(@"UIInterpolatingMotionEffect"))
    {
        [self.containerView.motionEffects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.containerView removeMotionEffect:obj];
        }];
    }
}
#endif

@end
