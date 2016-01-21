//
//  UncaughtExceptionHandler.h
//  UncaughtExceptions
//
//  Created by Matt Gallagher on 2010/05/25.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface CrashReport : NSObject <MFMailComposeViewControllerDelegate>

+ (instancetype)getInstance;
- (NSString *)getFilePath;
- (void)install;
- (void)uninstall;
- (BOOL)removeLogFile;
- (void)testBadAccess;
- (BOOL)writeLogWithString:(NSString *)logString;
- (void)sendLogsIfPresent;

@end

void installUncaughtExceptionHandler();
void uninstallUncaughtExceptionHandler();