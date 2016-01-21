//
//  QUIHelper.m
//  Expressome
//
//  Created by Dang Quan on 7/5/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "QUIHelper.h"
#import "ELoginViewController.h"

#define MAIN_STORYBOARD_NAME @"Main"

@implementation QUIHelper
+ (instancetype)getInstance {
    
    static QUIHelper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[QUIHelper alloc] init];
    });
    return _sharedInstance;
}

- (void)initWithMainWindow:(UIWindow *)window {
    self.window = window;
}

- (void)setRootViewController:(UIViewController *)viewController {
    self.window.rootViewController = viewController;
}

- (UIViewController *) getViewControllerWithIdentifier:(NSString *)identifier {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:MAIN_STORYBOARD_NAME bundle:nil];
    return [storyBoard instantiateViewControllerWithIdentifier:identifier];
}

- (void)showServerErrorAlert
{
    
    if ([[UIApplication sharedApplication] applicationState] ==  UIApplicationStateActive) {
        UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server is not available. Please try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [_alert show];
        
    } else {
        
        NSLog(@"Server is not available. Please try again.");
    }
    
}

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [_alert show];
}

- (void)showAlertLogoutMessage {
    UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"Your account has been logged in at another device. Please try to login again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [_alert show];
}

#pragma mark - UIAlertViewDelegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Clear user data
    [[EUserData getInstance] clear];
    
    // Do logging out
    ELoginViewController *loginVC = (ELoginViewController *)[self getViewControllerWithIdentifier:@"loginVC"];
    ENavigationController *navigationVC = (ENavigationController *)[self getViewControllerWithIdentifier:@"ENavigationControllerID"];
    [navigationVC setViewControllers:@[loginVC]];
    [self setRootViewController:navigationVC];
}

- (void)logoutDirectly {
    [[EUserData getInstance] clear];
    
    // Do logging out
    ELoginViewController *loginVC = (ELoginViewController *)[self getViewControllerWithIdentifier:@"loginVC"];
    ENavigationController *navigationVC = (ENavigationController *)[self getViewControllerWithIdentifier:@"ENavigationControllerID"];
    [navigationVC setViewControllers:@[loginVC]];
    [self setRootViewController:navigationVC];
}

@end
