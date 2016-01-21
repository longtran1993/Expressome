//
//  QAPIManager.m
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import "QAPIManager.h"

@implementation QAPIManager

+ (instancetype)getInstance {
    
    static QAPIManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[QAPIManager alloc] init];
    });
    return _sharedInstance;
}

- (AFHTTPRequestOperation *)operationWithURL:(NSString *)URLString
                                      method:(NSString *)methodName
                                  parameters:(id)parameters
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFJSONRequestSerializer *serializerRequest = [AFJSONRequestSerializer serializer];
    [serializerRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if(self.appendHeaderFields != nil) {
        [self.appendHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [serializerRequest setValue:obj forHTTPHeaderField:key];
        }];
    }
    NSMutableURLRequest *request = [serializerRequest requestWithMethod:methodName URLString:URLString parameters:parameters error:nil];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:success failure:failure];
    
    return operation;
}

- (void)GET:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block
{
    dispatch_queue_t apiRequestQueue = dispatch_queue_create("GET API Request Queue",NULL);
    dispatch_async(apiRequestQueue, ^{
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        if(self.appendHeaderFields != nil) {
            [self.appendHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
        
        [manager GET:apiURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            block(responseObject, nil);
            self.appendHeaderFields = nil;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            block(nil, error);
            self.appendHeaderFields = nil;
        }];
    });
}

- (void)POST:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block
{
    dispatch_queue_t apiRequestQueue = dispatch_queue_create("POST API Request Queue",NULL);
    dispatch_async(apiRequestQueue, ^{
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        if(self.appendHeaderFields != nil) {
            [self.appendHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
        
        [manager POST:apiURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSDictionary *dict = (NSDictionary *)responseObject;
//            NSNumber *statusCode = (NSNumber *)[dict objectForKey:@"code"];
//            if ([statusCode intValue] != 200) {
//                block(nil, nil);
//                return;
//            }
            block(responseObject,nil);
            self.appendHeaderFields = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            block(nil,error);
            self.appendHeaderFields = nil;
        }];
    });
}

- (void)PUT:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block
{
    dispatch_queue_t apiRequestQueue = dispatch_queue_create("PUT API Request Queue",NULL);
    dispatch_async(apiRequestQueue, ^{
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        if(self.appendHeaderFields != nil) {
            [self.appendHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
        
        [manager PUT:apiURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            block(responseObject,nil);
            self.appendHeaderFields = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            block(nil,error);
            self.appendHeaderFields = nil;
        }];
    });

}

- (void)DELETE:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block
{
    dispatch_queue_t apiRequestQueue = dispatch_queue_create("DELETE API Request Queue",NULL);
    dispatch_async(apiRequestQueue, ^{
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        if(self.appendHeaderFields != nil) {
            [self.appendHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
        
        [manager DELETE:apiURL parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            block(responseObject,nil);
            self.appendHeaderFields = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            block(nil,error);
            self.appendHeaderFields = nil;
        }];
    });

}

- (void)cancelAll
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.operationQueue cancelAllOperations];
}

@end
