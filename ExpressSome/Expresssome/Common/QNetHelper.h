//
//  QNetHelper.h
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"


typedef void (^QNetworkChangeBlock) (AFNetworkReachabilityStatus status);

@interface QNetHelper : NSObject

+ (id)getInstance;

- (BOOL)isNetworkAvailable;
- (BOOL)hasInternetConnection;
- (void)startMonitoring;
- (void)setStatusChangeBlock:(QNetworkChangeBlock)block;
@end
