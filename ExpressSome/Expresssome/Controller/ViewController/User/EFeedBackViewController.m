//
//  EFeedBackViewController.m
//  Expressome
//
//  Created by Quan DT on 7/30/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EFeedBackViewController.h"

@interface EFeedBackViewController ()
{
    NSArray *_feedBacks;
    NSInteger _currentFeedBack;
}

@property (nonatomic, strong) NSMutableArray *resultArray;
@property (nonatomic, strong) NSMutableArray *questions;
@property (nonatomic, strong) NSMutableArray *answers;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger countSuccess;
@property (nonatomic, assign) BOOL didShowSuccess;
@property (nonatomic, assign) NSInteger index;

@end

@implementation EFeedBackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _index = 0;
    _resultArray = [NSMutableArray arrayWithCapacity: 0];
    _questions = [NSMutableArray arrayWithCapacity: 0];
    _answers = [NSMutableArray arrayWithCapacity: 0];
    _currentFeedBack = -1;
    
    _feedBacks = @[@"Did you get confused at any point while using the app? If so, what confused you?",
                   @"Did you understand the difference between Round 1 and Round 2?",
                   @"What are your thoughts about the group chat?",
                   @"Do you like the duration of the rounds? If not, what duration would you prefer?",
                   @"Are there any features that you would like to see included or changed in future versions?",
                   @"Would you compete in a contest again?",
                   @"Was competing in a group with your friends fun?",
                   ];
    _questionLabel.numberOfLines = 0;
    _questionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _questionLabel.text = _feedBacks[0];
//    [_questionLabel sizeToFit];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backButtonTapped:(id)sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendButtonHasTapped:(id)sender {
    [self.view endEditing:YES];
    
    
    if (_index >= 7) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity: 2];
        [params setObject: _questions forKey: @"questions"];
        [params setObject: _answers forKey: @"answers"];
        [self sendToServerParam2: params];
      
    } else if([self isEmptyContent] ) {
        
        if (_index >= 6) {
            if (!_answers.count) {
                [self backButtonTapped: nil];
            } else {
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity: 2];
                [params setObject: _questions forKey: @"questions"];
                [params setObject: _answers forKey: @"answers"];
                [self sendToServerParam2: params];
                
            }
            
        } else {
            
            _index++;
            _questionLabel.text = _feedBacks[_index];
            //[_questionLabel sizeToFit];
            
            // Set number
            _numberLabel.text = [NSString stringWithFormat:@"%d/%d", _index + 1, _feedBacks.count];
        }
        
        
        
    } else {
        [_answers addObject: _contentTextView.text];
        _contentTextView.text = nil;
        
        NSString *question = [_feedBacks objectAtIndex: _index];
        [_questions addObject: question];
        
        _index++;
        if (_index >= 7) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity: 2];
            [params setObject: _questions forKey: @"questions"];
            [params setObject: _answers forKey: @"answers"];
            [self sendToServerParam2: params];
        } else {
            
            _questionLabel.text = _feedBacks[_index];
            //[_questionLabel sizeToFit];
            
            // Set number
            _numberLabel.text = [NSString stringWithFormat:@"%d/%d", _index + 1, _feedBacks.count];
        }
    }
    
    
}

- (BOOL)isValidInputs
{
    NSString *content = [_contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(content.length <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Feedback content is required" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return FALSE;
        
    }
    else if(content.length > 400) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Maximum characters of feedback content is 400" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)isEmptyContent
{
    NSString *content = [_contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return content.length > 0 ? FALSE : TRUE;
}

- (void)sendFeedBack {
    
     _currentFeedBack++;
    
    if (_currentFeedBack >= 7) {
        
        
        if (_resultArray.count > 0) {
            // Send to server
            [self sendToServer];
            
        } else {
            // Return
            [self.navigationController popViewControllerAnimated: YES];
        }
        
    } else {
        
        if(![self isEmptyContent]) {
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setValue:_feedBacks[_currentFeedBack] forKey:@"question"];
            [params setValue:_contentTextView.text forKey:@"answer"];
            
            [_resultArray addObject: params];
            
        }
        
        _contentTextView.text = @"";
        
        if (_currentFeedBack <= 5) {
            _questionLabel.text = _feedBacks[_currentFeedBack + 1];
            //[_questionLabel sizeToFit];
            
            // Set number
            _numberLabel.text = [NSString stringWithFormat:@"%d/%d", _currentFeedBack+2, _feedBacks.count];
        } else {
            if (_resultArray.count > 0) {
                // Send to server
                [self sendToServer];
                
            } else {
                // Return
                [self.navigationController popViewControllerAnimated: YES];
            }
        }
        
 
        
        
    }
    
  
}

- (void)sendToServerParam:(NSMutableDictionary *)params {
    
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl,kAPISendFeedBack];
    
    NSLog(@"PARAM: %@", [params objectForKey: @"answer"]);
   
    
    QAPIManager *apiManager = [QAPIManager getInstance];
    apiManager.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiManager.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    
    // Make request
    [apiManager POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        
        _count--;
        
        DLog_Low(@"API %@: %@", kAPISendFeedBack, responseObject);
        
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                // Reset text
                _contentTextView.text = @"";
                _countSuccess++;
               
            } else {
                if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                    NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                    if(codeStatus == kAPI403ErrorCode) {
                        [[QUIHelper getInstance] showAlertLogoutMessage];
                    }
                    else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                        [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                    }
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
        }
        else {
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
        
        
        if (_count <= 0) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if (_countSuccess > 0) {
                [[[UIAlertView alloc] initWithTitle:@"" message:@"Your feedback has been sent successfully" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
            }
            
            [self.navigationController popViewControllerAnimated: YES];
            
        } else {
            
            NSMutableDictionary *param = [_resultArray objectAtIndex: _count-1];
            
            [self performSelector: @selector(sendToServerParam:) withObject: params  afterDelay: 0.2];
            
            //[self sendToServerParam: param];
        }
        
    }];
}


- (void)sendToServer {
    
    // Show progress UI
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    _count = _resultArray.count;
    _countSuccess = 0;
    _didShowSuccess = false;
    //for (NSMutableDictionary *param in _resultArray) {
        
    NSMutableDictionary *param = [_resultArray objectAtIndex: _count-1];
    [self sendToServerParam: param];
        
   // }// for
    
    
}

#pragma mark - UITextViewDelegate -
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *description = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (description.length > 400) {
        return NO;
    }
    
    return YES;
}

#pragma mark - UIAlertViewDelegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)sendToServerParam2:(NSMutableDictionary *)params {
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    // Fill params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl,kAPISendFeedBack];
    
    NSLog(@"PARAM: %@", [params objectForKey: @"answer"]);
    
    
    QAPIManager *apiManager = [QAPIManager getInstance];
    apiManager.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiManager.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    
    // Make request
    [apiManager POST:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        DLog_Low(@"API %@: %@", kAPISendFeedBack, responseObject);
        
        if(!error) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                // Reset text
                _contentTextView.text = @"";
                
                [[[UIAlertView alloc] initWithTitle:@"" message:@"Your feedback has been sent successfully" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
                
            } else {
                if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                    NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                    if(codeStatus == kAPI403ErrorCode) {
                        [[QUIHelper getInstance] showAlertLogoutMessage];
                    }
                    else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                        [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                    }
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
        }
        else {
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
        
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        
        
        
    }];
}

@end
