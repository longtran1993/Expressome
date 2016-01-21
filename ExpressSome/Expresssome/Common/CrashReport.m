//
//  UncaughtExceptionHandler.m
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

#import "CrashReport.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";
NSString * const CrashFileName = @"crashed.txt";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation CrashReport

+ (instancetype)getInstance
{
    static CrashReport *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CrashReport alloc] init];
    });
    return sharedInstance;
}

+ (NSArray *)backtrace
{
	 void* callstack[128];
	 int frames = backtrace(callstack, 128);
	 char **strs = backtrace_symbols(callstack, frames);
	 
	 int i;
	 NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
	 for (
	 	i = UncaughtExceptionHandlerSkipAddressCount;
	 	i < UncaughtExceptionHandlerSkipAddressCount +
			UncaughtExceptionHandlerReportAddressCount;
		i++)
	 {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	 }
	 free(strs);
	 
	 return backtrace;
}


- (void)testBadAccess
{
//    void (*nullFunction)() = NULL;
//    
//    nullFunction();
    
    @throw([NSException exceptionWithName:@"Test" reason:@"Test" userInfo:nil]);
}

- (NSString *)getFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    return [dir stringByAppendingPathComponent:CrashFileName];
}

- (void)sendLogsIfPresent
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:[self getFilePath]])
    {
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"Expressome crashed", nil)
         message:NSLocalizedString(@"The app crashed last time it was launched. Send a crash report ?", nil)
         delegate:self
         cancelButtonTitle:NSLocalizedString(@"No Thanks", nil)
         otherButtonTitles:NSLocalizedString(@"Send Now", nil), nil];
        [alert show];
    }
}

- (BOOL)writeLogWithString:(NSString *)logString
{
    NSString *filePath = [self getFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:filePath])
    {
        [logString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    else
    {
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if(error) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)removeLogFile
{
    NSString *filePath = [self getFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![fileManager removeItemAtPath:filePath error:&error]) {
        return FALSE;
    }
    return TRUE;
}

- (void)install
{
    installUncaughtExceptionHandler();
}

- (void)uninstall
{
    uninstallUncaughtExceptionHandler();
}

- (void)sendEmail
{
    if ([MFMailComposeViewController canSendMail]) {
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:[self getFilePath]];
        
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[@"datdq@elarion.com", @"liennh@elarion.com", @"cuongnm@elarion.com", @"thienlh@elarion.com"]];
        [composeViewController setSubject:@"Expressome crash report"];
        [composeViewController addAttachmentData:data mimeType:@"text" fileName:[[self getFilePath] lastPathComponent]];
        
        [[self topViewController] presentViewController:composeViewController animated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
	if (index == 0) // No thanks
	{
        // Do nothing
	}
    else if(index == 1) { // Send now
        [self performSelector:@selector(sendEmail) withObject:nil afterDelay:1.5];
    }
}

- (void)handleException:(NSException *)exception
{
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterFullStyle];
    [self writeLogWithString:@"*************************************************************************************\n"];
    [self writeLogWithString:[NSString stringWithFormat:@"%@\n", dateString]];
    [self writeLogWithString:@"*************************************************************************************\n"];
    
    NSMutableString *exceptionString = [[NSMutableString alloc] initWithCapacity:4096];
    
    NSBundle *bundle = [NSBundle mainBundle];
    [exceptionString appendFormat:@"Expressome version %@ build %@\n\n",
     [bundle objectForInfoDictionaryKey:@"CFBundleVersion"],
     [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    [exceptionString appendString:@"Uncaught Exception\n"];
    [exceptionString appendFormat:@"Exception Name: %@\n",[exception name]];
    [exceptionString appendFormat:@"Exception Reason: %@\n",[exception reason]];
    [exceptionString appendFormat:@"Exception Description: %@\n",[exception description]];
    [exceptionString appendString:[NSString stringWithFormat:@"Stack trace:%@\n", [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]];
    [self writeLogWithString:exceptionString];
}

#pragma mark - ViewController Helper
- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

#pragma mark - Mail Composer Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if(result == MFMailComposeResultSent) {
        [self removeLogFile];
    }
    
    [controller dismissViewControllerAnimated:TRUE completion:nil];
}

@end

void handleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	//NSArray *callStack = [CrashReport backtrace];
    NSArray *callStack = [exception callStackSymbols];
	NSMutableDictionary *userInfo =
		[NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
		setObject:callStack
		forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[CrashReport getInstance]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:[exception name]
				reason:[exception reason]
				userInfo:userInfo]
		waitUntilDone:YES];
}

void signalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo =
		[NSMutableDictionary
			dictionaryWithObject:[NSNumber numberWithInt:signal]
			forKey:UncaughtExceptionHandlerSignalKey];

	NSArray *callStack = [CrashReport backtrace];
	[userInfo
		setObject:callStack
		forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[CrashReport getInstance]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
				reason:
					[NSString stringWithFormat:
						NSLocalizedString(@"Signal %d was raised.", nil),
						signal]
				userInfo:
					[NSDictionary
						dictionaryWithObject:[NSNumber numberWithInt:signal]
						forKey:UncaughtExceptionHandlerSignalKey]]
		waitUntilDone:YES];
}

void installUncaughtExceptionHandler()
{
	NSSetUncaughtExceptionHandler(&handleException);
	signal(SIGABRT, signalHandler);
	signal(SIGILL, signalHandler);
	signal(SIGSEGV, signalHandler);
	signal(SIGFPE, signalHandler);
	signal(SIGBUS, signalHandler);
	signal(SIGPIPE, signalHandler);
}

void uninstallUncaughtExceptionHandler()
{
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}

