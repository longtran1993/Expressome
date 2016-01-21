//
//  ERegisterViewController.m
//  Expresssome
//
//  Created by Quan DT on 4/14/15.
//  Copyright (c) 2015 VLandSoft. All rights reserved.
//

#import "ERegisterViewController.h"
#import "AFNetworking.h"
#import "ECommon.h"
#import "MBProgressHUD.h"
#import "EConstant.h"
#import "AppDelegate.h"
#import "IQKeyboardReturnKeyHandler.h"

@interface ERegisterViewController ()
{
    //IQKeyboardReturnKeyHandler *returnKeyHandler;
}

@end

@implementation ERegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    if ([_usernameTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor colorWithRed:59.0f/255.0f green:59.0f/255.0f blue:72.0f/255.0f alpha:1.0f];
        _usernameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username" attributes:@{NSForegroundColorAttributeName:color}];
        _passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:color}];
        _emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName:color}];
    }
    
    _errorLabel.text = @"";
    
    NSString *userName = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
    if (userName.length > 0) {
        [self performSegueWithIdentifier:@"profilePhotoSegue" sender:self];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];
    tapGesture.numberOfTapsRequired = 1;
    [_contentView addGestureRecognizer:tapGesture];
    
//    returnKeyHandler = [[IQKeyboardReturnKeyHandler alloc] initWithViewController:self];
//    [returnKeyHandler setLastTextFieldReturnKeyType:UIReturnKeyDone];
//    returnKeyHandler.toolbarManageBehaviour = IQAutoToolbarByPosition;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, _contentView.frame.size.height - 100)];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Set content size for scrollview
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
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = _contentView.frame;
        frame.origin.y = -130;
        _contentView.frame = frame;
    } completion:nil];
}

- (void)keyboardWillBeHidden
{
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = _contentView.frame;
        frame.origin.y = 0;
        _contentView.frame = frame;
    } completion:nil];
}

#pragma mark - Action

- (IBAction)joinButtonTapped:(id)sender {
    [self.view endEditing:YES];
    [self keyboardWillBeHidden];
    if ([self validateInputs]) {
        [self requestLogin];
    }
}

- (IBAction)backButtonTapped:(id)sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (BOOL)validateInputs
{
    BOOL isValid = YES;
    NSString *errorStr = @"";
    
    if (_usernameTextField.text.length < 5) {
        isValid = NO;
        errorStr = @"Username must be at least 5 characters";
    } else if ([ECommon isStringEmpty:_usernameTextField.text]) {
        isValid = NO;
        errorStr = @"Sorry, username is invalid. Please try another";
    }
    
    if (_passwordTextField.text.length < 6) {
        isValid = NO;
        if (errorStr.length > 0) {
            errorStr = [errorStr stringByAppendingString:@"\nPassword must be at least 6 characters"];
        } else {
            errorStr = @"Password must be at least 6 characters";
        }
    } else if ([ECommon isStringEmpty:_passwordTextField.text]) {
        isValid = NO;
        if (errorStr.length > 0) {
            errorStr = [errorStr stringByAppendingString:@"\nSorry, password is invalid. Please try another"];
        } else {
            errorStr = @"Sorry, password is invalid. Please try another";
        }
    }
    
    if (_emailTextField.text.length == 0) {
        isValid = NO;
        if (errorStr.length > 0) {
            errorStr = [errorStr stringByAppendingString:@"\nEmail is required"];
        } else {
            errorStr = @"Email is required";
        }
        
    } else {
        if (![ECommon isValidEmail:_emailTextField.text]) {
            isValid = NO;
            if (errorStr.length > 0) {
                errorStr = [errorStr stringByAppendingString:@"\nSorry, email is invalid. Please try another"];
            } else {
                errorStr = @"Sorry, email is invalid. Please try another";
            }
            
        }
    }
    
    if (!isValid) {
        _errorLabel.text = errorStr;
        _errorLabel.hidden = NO;
    } else {
        _errorLabel.hidden = YES;
    }
    
    return isValid;
}

#pragma mark - Send request

- (void)requestLogin
{
    if (![ECommon isNetworkAvailable]) return;
    
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Make request
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIRegisterPath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:_usernameTextField.text forKey:kAPIParamUsername];
    [params setValue:_passwordTextField.text forKey:kAPIParamPassword];
    [params setValue:_emailTextField.text forKey:kAPIParamEmail];
    [params setValue:[UIDevice currentDevice].systemVersion forKey:kAPIParamDeviceName];
    [params setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:kAPIParamDeviceId];
    [params setValue:@"iOS" forKey:@"deviceType"];
    if([[EUserData getInstance] objectForKey:DEVICE_TOKEN_UD_KEY]) {
        [params setValue:[[EUserData getInstance] objectForKey:DEVICE_TOKEN_UD_KEY] forKey:kAPIParamMachineCode];
    }
    
    [[QAPIManager getInstance] POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        if(!error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate registerPushNotificationForApplication:[UIApplication sharedApplication]];

                [[EUserData getInstance] setObject:_usernameTextField.text forKey:USER_NAME_UD_KEY];
                [[EUserData getInstance] setObject:_passwordTextField.text forKey:PASSWORD_UD_KEY];
                [[EUserData getInstance] setObject:_emailTextField.text forKey:EMAIL_UD_KEY];
                
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                NSDictionary *userProfile = [data valueForKey:@"userProfile"];
                if (userProfile) {
                    [[EUserData getInstance] setObject:[userProfile valueForKey:@"id"] forKey:USER_ID_UD_KEY];
                }
                
                NSDictionary *deviceInfo = [data valueForKey:@"deviceInfo"];
                if (deviceInfo) {
                    [[EUserData getInstance] setObject:[deviceInfo valueForKey:@"id"] forKey:DEVICE_ID_UD_KEY];
                }
                
                NSDictionary *authToken = [data valueForKey:@"authToken"];
                if (authToken) {
                    [[EUserData getInstance] setObject:[authToken valueForKey:@"token"] forKey:AUTH_TOKEN_UD_KEY];
                }
                
                _errorLabel.hidden = YES;
                _errorLabel.text = @"";
                
                [self performSegueWithIdentifier:@"profilePhotoSegue" sender:self];
            } else {
                NSInteger code = [[responseObject valueForKey:@"code"] integerValue];
                if (code == 701) {
                    _errorLabel.text = @"An account has already been created with this username.\nPlease try a different username.";
                }
                else if (code == 702) {
                    _errorLabel.text = @"An account has already been created with this email address.\nPlease try a different email.";
                }
                else {
                    _errorLabel.text = [responseObject valueForKey:kAPIResponseMessage];
                }
                _errorLabel.hidden = NO;
                
            }
        }
        else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (IS_IPHONE_4_OR_LESS) {
        [self keyboardWasShown];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_emailTextField becomeFirstResponder];
    } else if (textField == _emailTextField) {
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
