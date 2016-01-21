//
//  EJSONHelper.m
//  Expressome
//
//  Created by Quan DT on 7/18/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EJSONHelper.h"

@implementation EJSONHelper

+ (id)valueFromData:(id)data {
    if(data != nil && data != [NSNull null]) {
        return data;
    }
    return nil;
}

+ (void)logJSON:(id)data toFile:(NSString *)fileName {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"%s: error: %@", __FUNCTION__, error.localizedDescription);
    } else {
        NSString *cacheDir = [[QSystemHelper getInstance] cacheDirectory];
        if(![[QSystemHelper getInstance] saveFileWithName:fileName andData:jsonData inPath:[cacheDir stringByAppendingPathComponent:@"logs"]]) {
            NSLog(@"%s: failed", __FUNCTION__);
        }
    }
}

@end
