//
//  SIAlertViewController.h
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SIAlertView;

@interface SIAlertViewController : UIViewController

@property (nonatomic, strong) SIAlertView *alertView;
#ifdef __IPHONE_7_0
@property (nonatomic, assign) BOOL statusBarHidden;
#endif

@end

