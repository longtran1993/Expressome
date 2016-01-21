//
//  EJSONHelper.h
//  Expressome
//
//  Created by Quan DT on 7/18/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EJSONHelper : NSObject

+(id)valueFromData:(id)data;
+ (void)logJSON:(id)data toFile:(NSString *)fileName;

@end
