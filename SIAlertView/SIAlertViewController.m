//
//  SIAlertViewController.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertViewController.h"
#import "SIAlertView.h"

@implementation SIAlertViewController

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
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

#pragma mark - View rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.alertView resetTransition];
    [self.alertView invalidateLayout];
}

#ifdef __IPHONE_7_0
- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}
#endif

@end
