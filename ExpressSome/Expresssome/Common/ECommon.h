//
//  ECommon.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EConstant.h"

@interface ECommon : NSObject

+ (BOOL)isNetworkAvailable;
+ (void)showServerErrorAlert;
+ (BOOL)isValidEmail:(NSString *)checkString;
+ (NSString *)imagesFolderPath;
+ (NSString*)resetNullValueToString:(NSString*)_value;
+ (BOOL)isStringEmpty:(NSString *)string;
+ (BOOL)doesStringContainSpace:(NSString *)str;
+ (void)showAlertWithMessage:(NSString *)message;
+ (void)playNotificationSound;
+ (UIImage *)resizeImage:(UIImage *)image  ToSize:(CGSize)size;
+ (UIImage *)scaleImage:(UIImage *)image  ToSize:(CGSize)size;


@end
