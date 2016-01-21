//
//  QNotificationHelper.m
//  Expressome
//
//  Created by Quan DT on 7/11/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "QNotificationHelper.h"
#import "EConstant.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation QNotificationHelper
+ (instancetype)getInstance {
    
    static QNotificationHelper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[QNotificationHelper alloc] init];
    });
    return _sharedInstance;
}

- (NSInteger)getBadgeNumber {
    return (NSInteger)[UIApplication sharedApplication].applicationIconBadgeNumber;
}

- (void)setBadgeNumber:(NSInteger)number {
    [UIApplication sharedApplication].applicationIconBadgeNumber = number;
}

- (void)descreaseBadgeNumberBy:(NSInteger)number {
    if([UIApplication sharedApplication].applicationIconBadgeNumber >= number) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - number;
    }
    else {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
}

- (void)resetBadgeForType:(NSString *) type {
    // Check network connection
    if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    
    // Fill params
    QAPIManager *apiMgr = [QAPIManager getInstance];
    apiMgr.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiMgr.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIResetBadgePath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:type forKey:@"notifyType"];
    
    // Make request
    [apiMgr POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        DLog_Low(@"RESET_BADGE_RESPONE: %@", responseObject);
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                
                // Set new badge number
                //[UIApplication sharedApplication].applicationIconBadgeNumber = [[data objectForKey:@"badge"] integerValue];
                
//                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Badge Number : %@", [data objectForKey:@"badge"]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//                [alertView show];
            }
        }
    }];
}

- (void)playNotificationSound
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"Tribal Notification" ofType:@"wav"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}
@end
