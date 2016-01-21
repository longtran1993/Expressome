//
//  EResetPasswordViewController.m
//  Expressome
//
//  Created by Quan DT on 7/15/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EResetPasswordViewController.h"

@interface EResetPasswordViewController ()

@end

@implementation EResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Hide navigation bar
    self.navigationController.navigationBarHidden = YES;
    
    // Secure entry text
    self.passwordTextField.secureTextEntry = YES;
    self.confirmPasswordTextField.secureTextEntry = YES;
    
    // Custom clear button
    [[self.passwordTextField valueForKey:@"_clearButton"] setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
    [[self.confirmPasswordTextField valueForKey:@"_clearButton"] setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reset content size
    CGSize newSize = self.contentView.frame.size;
    newSize.height += 5;
    self.scrollView.contentSize = newSize;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UI Action -
- (IBAction)backButtonHasTapped:(id)sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Other Methods -
- (BOOL)isValidInputs {
    BOOL isValid = YES;
    NSString *errorStr = @"";
    
    if(_passwordTextField.text.length == 0) {
        isValid = NO;
        errorStr = @"Password is required";
    }
    else if (_passwordTextField.text.length < 6) {
        isValid = NO;
        errorStr = @"Password must be at least 6 characters";
    }
    else {
        if(![_passwordTextField.text isEqualToString:_confirmPasswordTextField.text]) {
            isValid = NO;
            errorStr = @"Entered passwords do not match";
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

- (void)resetPassword {
    // Check network connection
    if (![[QNetHelper getInstance] isNetworkAvailable])
        return;
    
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl,kAPISetPasswordPath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:_passwordTextField.text forKey:@"newPassword"];
    [params setValue:_confirmPasswordTextField.text forKey:@"confirmPassword"];
    [params setValue:_token forKey:@"token"];
    
    // Make request
    [[QAPIManager getInstance] POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        DLog_Low(@"API %@: %@", kAPIRequestPasswordPath, responseObject);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                // Show success alert view
                UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Your password has been changed successfully" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [_alert show];
                
                // Hide error label
                _errorLabel.hidden = YES;
                _errorLabel.text = @"";
                
            } else {
                // Display error label
                _errorLabel.text = [responseObject valueForKey:kAPIResponseMessage];
                _errorLabel.hidden = NO;
                
            }
        }
        else {
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
        
    }];
}

#pragma mark - UITextFieldDelegate -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if([textField isEqual:self.confirmPasswordTextField]) {
        if([self isValidInputs]) {
            [self resetPassword];
        }
    }
    else {
        [self.confirmPasswordTextField becomeFirstResponder];
    }
    return YES;
}

#pragma mark - UIAlertViewDelegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Go to login view
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIScrollViewDelegate -
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}


@end
