//
//  QUIHelper.h
//  Expressome
//
//  Created by Dang Quan on 7/5/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUIHelper : NSObject <UIAlertViewDelegate>

@property (assign, nonatomic) UIWindow *window;

+ (instancetype)getInstance;

- (void)initWithMainWindow:(UIWindow *)window;
- (void)setRootViewController:(UIViewController *)viewController;
- (UIViewController *) getViewControllerWithIdentifier:(NSString *)identifier;

- (void)showServerErrorAlert;
- (void)showAlertWithMessage:(NSString *)message;
- (void)showAlertLogoutMessage;
- (void)logoutDirectly;
@end
