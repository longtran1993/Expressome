//
//  QNetHelper.m
//  Expressome
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "QNetHelper.h"
#import "Reachability.h"
#import "AFNetworkActivityLogger.h"

@implementation QNetHelper

+ (instancetype)getInstance {
    
    static QNetHelper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[QNetHelper alloc] init];
    });
    return _sharedInstance;
}

- (BOOL)isNetworkAvailable {
    
    
    return YES;
    
    
    // Because the Reachability && AFNetworking can not return state of internet immediatly, so we will check internet by this way.
    Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"No Internet Connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        return FALSE;
    }
    return TRUE;
}

- (BOOL)hasInternetConnection {
    
    
    return YES;
    
    /////
    // Because the Reachability && AFNetworking can not return state of internet immediatly, so we will check internet by this way.
    Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
    {
        return FALSE;
    }
    return TRUE;
}

- (void)startMonitoring {
    // Start logger
#ifdef DEBUG
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
#endif
    
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)setStatusChangeBlock:(QNetworkChangeBlock)block {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:block];
}

@end
