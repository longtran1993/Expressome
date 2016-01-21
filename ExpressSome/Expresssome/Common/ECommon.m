//
//  ECommon.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ECommon.h"
#import "Reachability.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AFNetworking.h"

@implementation ECommon

//check network avaiable
+ (BOOL)isNetworkAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
//    if(![AFNetworkReachabilityManager sharedManager].reachable) {
        UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"No Internet Connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [_alert show];
        
        return NO;
    }
    return YES;
}

+ (void)showServerErrorAlert
{
    UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"Server is not available. Please try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [_alert show];
}

+ (BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

+ (NSString *)imagesFolderPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Images"];
}

+ (NSString*)resetNullValueToString:(NSString*)_value
{
    if (_value == (id)[NSNull null] || _value == nil) {
        return @"";
    }
    
    return _value;
}

+ (BOOL)isStringEmpty:(NSString *)string {
    if ([string length] == 0) {
        return YES;
    }
    
    if (![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)doesStringContainSpace:(NSString *)str
{
    NSRange whiteSpaceRange = [str rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whiteSpaceRange.location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

+ (void)showAlertWithMessage:(NSString *)message
{
    UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [_alert show];
}

+ (void)playNotificationSound
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"Tribal Notification" ofType:@"wav"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

+ (UIImage *)resizeImage:(UIImage *)image  ToSize:(CGSize)size {
    
    @autoreleasepool {
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, size.width, size.width)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = image;
//        
//        UIGraphicsBeginImageContext(imageView.bounds.size);
//        [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
//        
//        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//        NSData *data = UIImageJPEGRepresentation( newImage,  1.0);//0.7
//        newImage = [UIImage imageWithData: data];
//        
//        UIGraphicsEndImageContext();
        
        return image;
    }

}

+ (UIImage *)scaleImage:(UIImage *)image  ToSize:(CGSize)size {
    
    @autoreleasepool {
        
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        NSData *data = UIImageJPEGRepresentation( newImage,  0.7);//0.7
        newImage = [UIImage imageWithData: data];
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
}



@end
