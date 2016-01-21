//
//  ELoginViewController.m
//  Expresssome
//
//  Created by QuanDT on 4/14/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import "ELoginViewController.h"
#import "AFNetworking.h"
#import "ECommon.h"
#import "MBProgressHUD.h"
#import "EConstant.h"
#import "AppDelegate.h"
#import "ECreateGroupViewController.h"
#import "ERegisterViewController.h"
#import "AFNetworking.h"

@interface ELoginViewController ()
{
    
}

@end

@implementation ELoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Fix #646: change error alert style
    _errorLabel.hidden = YES;
    
    // Hide navigation bar
    self.navigationController.navigationBarHidden = YES;

    UIColor *color = [UIColor colorWithRed:59.0f/255.0f green:59.0f/255.0f blue:72.0f/255.0f alpha:1.0f];
    if ([_usernameTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        _usernameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username or email" attributes:@{NSForegroundColorAttributeName:color}];
    }
    
    if ([_passwordTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        _passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:color}];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];
    tapGesture.numberOfTapsRequired = 1;
    [_contentView addGestureRecognizer:tapGesture];
    
    // Set style for signup button
//    NSRange textRange = [self.signUpLabel.text rangeOfString:@"Signup"];
//    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.signUpLabel.text];
//    self.signUpLabel.text = @"";
//    [attributedString beginEditing];
//    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:14] range:textRange];
//    [attributedString endEditing];
//    self.signUpLabel.attributedText = attributedString;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Set content size for scrollview
    [_scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, _contentView.frame.size.height)];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //_errorLabel.text = @"";
    //_errorLabel.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //_errorLabel.text = @"";
    //_errorLabel.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)closeKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - Keyboard Control

- (void)keyboardWasShown
{
//    [UIView animateWithDuration:0.3f animations:^{
//        CGRect frame = _contentView.frame;
//        frame.origin.y = -130;
//        _contentView.frame = frame;
//    } completion:nil];
}

- (void)keyboardWillBeHidden
{
//    [UIView animateWithDuration:0.3f animations:^{
//        CGRect frame = _contentView.frame;
//        frame.origin.y = 0;
//        _contentView.frame = frame;
//    } completion:nil];
}

#pragma mark - Action

- (IBAction)loginButtonTapped:(id)sender {
    [self.view endEditing:YES];
    //[self keyboardWillBeHidden];
    if ([self validateInputs]) {
        [self requestLogin];
    }
}

- (IBAction)registerButtonTapped:(id)sender {
    ERegisterViewController *registerVC = (ERegisterViewController *) [[QUIHelper getInstance] getViewControllerWithIdentifier:@"registerVC"];
    [self.navigationController pushViewController:registerVC animated:TRUE];
    
}

- (BOOL)validateInputs
{
    if (_usernameTextField.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Username/Email is required" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return FALSE;
    }
    else {
        if ([_usernameTextField.text rangeOfString:@"@"].location == NSNotFound) {
            if (_usernameTextField.text.length < 5) {
                [[[UIAlertView alloc] initWithTitle:@"" message:@"Username must be at least 6 characters" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
                return FALSE;
            }
        }
        else {
            if(![ECommon isValidEmail:_usernameTextField.text]) {
                [[[UIAlertView alloc] initWithTitle:@"" message:@"Email is invalid" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
                return FALSE;
            }
        }
    }
    
    if (_passwordTextField.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Password is required" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return FALSE;
    }
    else {
        if(_passwordTextField.text.length < 6) {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Password must be at least 6 characters" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
            return FALSE;
        }
    }
    
    
    return TRUE;
//    BOOL isValid = YES;
//    NSString *errorStr = @"";
//    
//    if (_usernameTextField.text.length == 0) {
//        isValid = NO;
//        errorStr = @"Username/Email is required";
//    } else {
//        if ([_usernameTextField.text rangeOfString:@"@"].location == NSNotFound) {
//            if (_usernameTextField.text.length < 5) {
//                isValid = NO;
//                errorStr = @"Username must be at least 6 characters";
//            }
//        } else {
//            if(![ECommon isValidEmail:_usernameTextField.text]) {
//                isValid = NO;
//                errorStr = @"Email is invalid";
//            }
//        }
//    }
//    
//    if (_passwordTextField.text.length < 6) {
//        isValid = NO;
//        if (errorStr.length > 0) {
//            errorStr = [errorStr stringByAppendingString:@"\nPassword must be at least 6 characters"];
//        } else {
//            errorStr = @"Password must be at least 6 characters";
//        }
//    } else if ([ECommon isStringEmpty:_passwordTextField.text]) {
//        isValid = NO;
//        if (errorStr.length > 0) {
//            errorStr = [errorStr stringByAppendingString:@"\nSorry, password is invalid. Please try another"];
//        } else {
//            errorStr = @"Sorry, password is invalid. Please try another";
//        }
//    }
//    
//    if (!isValid) {
//        _errorLabel.text = errorStr;
//        _errorLabel.hidden = NO;
//    } else {
//        _errorLabel.hidden = YES;
//    }
//    
//    return isValid;
}

- (void)saveImage:(NSString *)imagePath
{
    NSString *fullPath = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imagePath];
    dispatch_queue_t queue = dispatch_queue_create("Download Profile Photo",NULL);
    dispatch_async(queue, ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:fullPath]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(imageData) {
                // Save profile photo in local
                QSystemHelper *systemHelper = [QSystemHelper getInstance];
                NSString *cacheDir = [systemHelper cacheDirectory];
                NSString *fileName = [NSString stringWithFormat:@"%@.png", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]];
                NSString *filePath = [cacheDir stringByAppendingPathComponent:kAvatarImagePath];
                BOOL success = [systemHelper saveFileWithName:fileName andData:imageData inPath:filePath];
                if(!success) {
                    NSLog(@"%s Failed to save profile photo", __FUNCTION__);
                }
            }
        });
    });
}
#pragma mark - Send request

- (void)requestLogin
{
    // Check network connection
    if (![ECommon isNetworkAvailable]) return;
   
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
   
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl,kAPILoginPath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:_passwordTextField.text forKey:kAPIParamPassword];
    if ([_usernameTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [params setValue:_usernameTextField.text forKey:kAPIParamUsername];
    }
    else {
        [params setValue:_usernameTextField.text forKey:kAPIParamEmail];
    }
    [params setValue:[UIDevice currentDevice].systemVersion forKey:kAPIParamDeviceName];
    [params setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:kAPIParamDeviceId];
    [params setValue:@"iOS" forKey:@"deviceType"];
    if([[EUserData getInstance] objectForKey:DEVICE_TOKEN_UD_KEY]) {
        [params setValue:[[EUserData getInstance] objectForKey:DEVICE_TOKEN_UD_KEY] forKey:kAPIParamMachineCode];
    }
    
    // Make request
    [[QAPIManager getInstance] POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        DLog_Low(@"JSON: %@", responseObject);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate registerPushNotificationForApplication:[UIApplication sharedApplication]];
                
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                NSDictionary *userProfile = [data valueForKey:@"userProfile"];
                
                [[EUserData getInstance] setObject:_passwordTextField.text forKey:PASSWORD_UD_KEY];
                [[EUserData getInstance] setObject:_usernameTextField.text forKey:USER_NAME_UD_KEY];
                
                if (userProfile) {
                    [[EUserData getInstance] setObject:[userProfile valueForKey:@"id"] forKey:USER_ID_UD_KEY];
                    [[EUserData getInstance] setObject:[userProfile objectForKey:@"email"] forKey:EMAIL_UD_KEY];
                    
                    // Save profile photo to local
                    if([userProfile objectForKey:@"image"] != nil && [userProfile objectForKey:@"image"] != [NSNull null]) {
                        NSString *imagePath = [userProfile objectForKey:@"image"];
                        if(imagePath.length > 0) {
                            [[EUserData getInstance] setObject:[ECommon resetNullValueToString:imagePath] forKey:AVATAR_PATH_UD_KEY];
                            [self saveImage:imagePath];
                        }
                    }
                }
                
                NSDictionary *deviceInfo = [data valueForKey:@"deviceInfo"];
                if (deviceInfo) {
                    [[EUserData getInstance] setObject:[deviceInfo valueForKey:@"id"] forKey:DEVICE_ID_UD_KEY];
                }
                
                NSDictionary *authToken = [data valueForKey:@"authToken"];
                if (authToken) {
                    [[EUserData getInstance] setObject:[authToken valueForKey:@"token"] forKey:AUTH_TOKEN_UD_KEY];
                }
                
                //_errorLabel.hidden = YES;
                //_errorLabel.text = @"";
                
                if([userProfile valueForKey:@"group"] && [userProfile valueForKey:@"group"] != [NSNull null]) {
                    NSInteger groupID = [[userProfile valueForKey:@"group"] integerValue];
                    [self getDetailGroupInfo:groupID];
                }
                else {
                    // Switch wiew controller
                    NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
                    if (groupInfo != nil) {
                        ETabBarController *tabBar = (ETabBarController *) [[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
                        tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
                        [[QUIHelper getInstance] setRootViewController:tabBar];
                    } else {
                        ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
                        ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
                        [navigationVC setViewControllers:@[createGroupVC]];
                        [[QUIHelper getInstance] setRootViewController:navigationVC];
                    }
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"" message:[responseObject valueForKey:kAPIResponseMessage] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
//                _errorLabel.text = [responseObject valueForKey:kAPIResponseMessage];
//                _errorLabel.hidden = NO;
                
            }
        }
        else {
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
        
    }];
}

- (void)getDetailGroupInfo:(NSInteger)groupID
{
    // Check network connection
    if (![ECommon isNetworkAvailable]) return;
    
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIDetailGroupPath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInteger:groupID] forKey:kAPIParamGroupID];
    
    // Make request
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DLog_Low(@"JSON: %@", responseObject);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                if(data) {
                    [[EUserData getInstance] setData:data forKey:GROUP_INFO_UD_KEY];
                }
                
                // Switch wiew controller
                NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
                if (groupInfo != nil) {
                    ETabBarController *tabBar = (ETabBarController *) [[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
                    tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
                    [[QUIHelper getInstance] setRootViewController:tabBar];
                } else {
                    ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
                    ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
                    [navigationVC setViewControllers:@[createGroupVC]];
                    [[QUIHelper getInstance] setRootViewController:navigationVC];
                }
            }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
         DLog_Error(@"Error: %@", error);
         [[QUIHelper getInstance] showServerErrorAlert];
     }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
//    if (IS_IPHONE_4_OR_LESS) {
//        [self keyboardWasShown];
//    }
//
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
    } else {
        [self.view endEditing:YES];
    }
    
    return YES;
}

#pragma mark - UIStatusBar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}



@end
