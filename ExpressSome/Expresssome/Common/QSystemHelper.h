//
//  QSystemHelper.h
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)


#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)



// Define Log function by level. Set LOG_LEVEL to 1 when distribute
#define DEBUG                           1
#define LOG_LEVEL                       4

#if (DEBUG == 1)

#if (LOG_LEVEL >= 4)
#   define DLog_Low(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog_Low(...)
#endif

#if (LOG_LEVEL >= 3)
#   define DLog_Med(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog_Med(...)
#endif

#if (LOG_LEVEL >= 2)
#   define DLog_High(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog_High(...)
#endif

#if (LOG_LEVEL >= 1)
#   define DLog_Error(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog_Error(...)
#endif

#else

#define DLog_Low(...)
#define DLog_Med(...)
#define DLog_High(...)
#define DLog_Error(...)

#endif


@interface QSystemHelper : NSObject

+ (instancetype)getInstance;

// Date time
+ (NSString *)timeAPMForDate:(NSDate *) date;
+ (NSDate *)dateFromUTCString:(NSString *)dateStr;
+ (NSString *)UTCStringFromDate:(NSDate *)date;
+ (NSDate *)localDateFromUTCString:(NSString *)dateStr;

// File system
- (NSString *)cacheDirectory;
- (BOOL)saveImage:(UIImage *)image withName:(NSString *)name ToPath:(NSString *)path;
- (UIImage *)imageAtPath:(NSString *)path;
- (BOOL)saveFileWithName:(NSString *)name andData:(NSData *)data inPath:(NSString *)path;
- (NSArray *)dataContentsAtPath:(NSString *)path withExtension:(NSString *)extension;
- (BOOL)deleteAllFilesInPath:(NSString *)path;
@end
