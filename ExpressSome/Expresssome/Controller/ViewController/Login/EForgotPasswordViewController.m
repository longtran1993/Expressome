//
//  EForgotPasswordViewController.m
//  Expressome
//
//  Created by Quan DT on 7/15/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EForgotPasswordViewController.h"
#import "EResetPasswordViewController.h"

@interface EForgotPasswordViewController ()

@end

@implementation EForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Custom clear button
    [[self.emailTextField valueForKey:@"_clearButton"] setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)doneButtonHasTapped:(id)sender {
    // Hide popup
    [self showPopup:NO];
    
//    // Go to reset passsword
//    EResetPasswordViewController *resetPasswordVC = (EResetPasswordViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"resetPasswordVC"];
//    [self.navigationController pushViewController:resetPasswordVC animated:YES];
    
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Other Methods -
- (BOOL)isValidInputs {
    BOOL isValid = YES;
    NSString *errorStr = @"";
    
    if (_emailTextField.text.length == 0) {
        isValid = NO;
        errorStr = @"Username/Email is required";
    } else {
        if ([_emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
            if (_emailTextField.text.length < 5) {
                isValid = NO;
                errorStr = @"Username must be at least 6 characters";
            }
        } else {
            if(![ECommon isValidEmail:_emailTextField.text]) {
                isValid = NO;
                errorStr = @"Email is invalid";
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

- (void)showPopup:(BOOL)show
{
    [UIView animateWithDuration:0.3f animations:^{
        _popupView.hidden = !show;
    } completion:nil];
}

- (void)requestPassword {
    // Check network connection
    if (![[QNetHelper getInstance] isNetworkAvailable])
        return;
    
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl,kAPIRequestPasswordPath];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if ([_emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [params setValue:_emailTextField.text forKey:kAPIParamUsername];
    }
    else {
        [params setValue:_emailTextField.text forKey:kAPIParamEmail];
    }
    
    // Make request
    [[QAPIManager getInstance] POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        DLog_Low(@"API %@: %@", kAPIRequestPasswordPath, responseObject);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                // Show popup
                [self showPopup:TRUE];
                
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
    
    if([self isValidInputs]) {
        [self requestPassword];
    }
    
    return YES;
}

#pragma mark - UIScrollViewDelegate -
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}


@end
