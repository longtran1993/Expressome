//
//  EImageView.m
//  Expresssome
//
//  Created by Nguyen Thong Thai on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EImageView.h"
#import "AFNetworking.h"
#import "EUserDefault.h"
#import "EConstant.h"

@interface EImageView ()
{
    AFHTTPRequestOperation *get;
}

@end

@implementation EImageView

- (void)downloadImageWithType:(NSString *)type idNumber:(NSNumber *)idNumber
{
//    if (get) {
//        [get cancel];
//        get = nil;
//    }
//    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    [manager.requestSerializer setValue:[EUserDefault getAuthToken] forHTTPHeaderField:@"auth-token"];
//    
//    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIDownloadImagePath];
//    
//    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
//    [params setValue:type forKey:@"entityName"];
//    [params setValue:idNumber forKey:@"recordId"];
//    
//    get = [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//
//        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
//        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
//            
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        DLog_Error(@"Error: %@", error);
//    }];
}

@end
