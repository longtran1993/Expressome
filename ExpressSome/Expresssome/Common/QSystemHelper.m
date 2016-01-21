//
//  QSystemHelper.m
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "QSystemHelper.h"

@implementation QSystemHelper

+ (instancetype)getInstance {
    
    static QSystemHelper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[QSystemHelper alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)timeAPMForDate:(NSDate *) date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    return [dateFormatter stringFromDate:date];
}

+ (NSDate *)dateFromUTCString:(NSString *)dateStr
{
    NSString *fmDateStr = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fmDateStr];
    return [dateFormatter dateFromString:dateStr];
}

+ (NSDate *)localDateFromUTCString:(NSString *)dateStr
{
    NSDate *utcDate = [QSystemHelper dateFromUTCString:dateStr];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSTimeInterval timeInterval = [timeZone secondsFromGMTForDate:utcDate];
    return [NSDate dateWithTimeInterval:timeInterval sinceDate:utcDate];
}

+ (NSString *)UTCStringFromDate:(NSDate *)date
{
    NSString *fmDateStr = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:fmDateStr];
    return [dateFormatter stringFromDate:date];
}

- (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    return cacheDirectory;
}

- (BOOL)fileExistAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSArray *)dataContentsAtPath:(NSString *)path withExtension:(NSString *)extension {
    NSString *fullPath = [[self cacheDirectory] stringByAppendingPathComponent:path];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *dirContents = [manager contentsOfDirectoryAtPath:fullPath error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"self ENDSWITH '%@'", extension]];
    NSArray *filePaths = [dirContents filteredArrayUsingPredicate:fltr];    
    return filePaths;
}

- (BOOL)saveFileWithName:(NSString *)name andData:(NSData *)data inPath:(NSString *)path
{
    BOOL result = YES;
    BOOL isDirectory = YES;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        result = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }

    if(error == nil) {
        result = [data writeToFile:[path stringByAppendingPathComponent:name]  atomically:YES];
    }
    else {
        NSLog(@"%s Failed to save file with name %@", __FUNCTION__, name);
    }
    
    return result;
}

- (BOOL)deleteAllFilesInPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [[self cacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/", path]];
    NSError *error = nil;
    BOOL isSuccess = TRUE;
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, file] error:&error];
        if (!success || error) {
            // it failed.
            isSuccess = FALSE;
        }
    }
    return isSuccess;
}

- (BOOL)saveImage:(UIImage *)image withName:(NSString *)name ToPath:(NSString *)path
{
    NSData *data = UIImagePNGRepresentation(image);
    return [self saveFileWithName:name andData:data inPath:path];
}

- (UIImage *)imageAtPath:(NSString *)path {
    if([self fileExistAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}
@end
