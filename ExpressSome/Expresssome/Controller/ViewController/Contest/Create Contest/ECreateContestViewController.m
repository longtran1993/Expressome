//
//  ECreateContestViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/9/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ECreateContestViewController.h"
#import "ECommon.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "EContestPageViewController.h"
#import "IQUIView+IQKeyboardToolbar.h"
#import "ECreateGroupViewController.h"
#import "OKAlert.h"

#define kDescriptionTextMaxLength 400

@interface ECreateContestViewController () <RSKImageCropViewControllerDelegate>
{
    BOOL didSelectPhoto;
    NSMutableArray *listGroup;
    NSMutableDictionary *contestInfo;
    UIImage *currentSelectImage;
    UIImagePickerController *_imagePickerController;
}

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) OKAlert *okAlert;
@property (nonatomic, assign) BOOL allowCreatingContest;


@end

@implementation ECreateContestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _count = 0;

    _allowCreatingContest = YES;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardWillBeHidden)];
    tapGesture.numberOfTapsRequired = 1;
    [_scrollView addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardWillBeHidden)];
    swipe.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    swipe.delegate = self;
    [_scrollView addGestureRecognizer:swipe];
    
    UITapGestureRecognizer *photoTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoImageViewTapped)];
    photoTapGesture.numberOfTapsRequired = 1;
    [_photoImageView addGestureRecognizer:photoTapGesture];
    _photoImageView.userInteractionEnabled = YES;
    
    [self checkInputWithTitle:_titleTextField.text description:_descriptionTextView.text];
    
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 644.0f)];
    
    listGroup = [[NSMutableArray alloc] init];
    [listGroup addObject:[[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY]];
    
    // Custom clear button
    [[self.titleTextField valueForKey:@"_clearButton"] setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
    
    // Set placeholder for description textview
    self.descriptionTextView.placeholder = @"Add Contest Description";
    
    [self reloadListGroupLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)checkInputWithTitle:(NSString *)title description:(NSString *)description
{
    if (didSelectPhoto == NO || [ECommon isStringEmpty:title] || [ECommon isStringEmpty:description]) {
        [_createButton setTitleColor:[UIColor colorWithRed:176.0f/255.0f green:174.0f/255.0f blue:183.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _createButton.enabled = NO;
        return NO;
    } else {
        [_createButton setTitleColor:[UIColor colorWithRed:121.0f/255.0f green:34.0f/255.0f blue:156.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _createButton.enabled = YES;
    }
    
    return YES;
}

- (void)reloadListGroupLabel
{
    NSInteger currentGroupId = [[[[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY] valueForKey:@"id"] integerValue];
    
    NSString *str = @"";
    for (NSDictionary *dict in listGroup) {
        if (currentGroupId != [[dict valueForKey:@"id"] integerValue]) {
            if (str.length == 0) {
                str = [dict valueForKey:@"name"];
            } else {
                str = [str stringByAppendingString:[NSString stringWithFormat:@", %@", [dict valueForKey:@"name"]]];
            }
        }
    }
    _inviteTextField.text = str;
    
    _countLabel.text = [NSString stringWithFormat:@"%lu/%d", (unsigned long)listGroup.count, kMaxInvitingGroupNumber];
}

- (void)adjustViews
{
//    // Set frame for inputHolderView
//    CGRect newFrame = _inputHolderView.frame;
//    newFrame.origin.y = _photoImageView.frame.origin.y + _photoImageView.frame.size.height;
//    _inputHolderView.frame = newFrame;
//    
//    // Adjust contentSize
//    CGSize newSize = _scrollView.contentSize;
//    newSize.height = _inputHolderView.frame.origin.y + _inputHolderView.frame.size.height;
//    _scrollView.contentSize = newSize;
}

#pragma mark - Action

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)inviteButtonTapped:(id)sender {
    
    [self keyboardWillBeHidden];
    
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EInviteGroupViewController *inviteGroupVC = (EInviteGroupViewController *)[sb instantiateViewControllerWithIdentifier:@"inviteGroupVC"];
    inviteGroupVC.deleagte = self;
    inviteGroupVC.listGroup = [[NSMutableArray alloc] initWithArray:listGroup];
    [self.navigationController pushViewController:inviteGroupVC animated:YES];
}

- (IBAction)createContestButtonTapped:(id)sender {
    
    if (listGroup.count < 2) {
        // Show alert
        
        if (!IS_NOT_NULL(_okAlert)) {
            _okAlert = [[OKAlert alloc] initWithDelegate: nil];
            _okAlert.lblMessage.text = @"On Expressome, you must invite one group to create a contest. Please select invite group to find a group to invite.";
            
        }
        
        [_okAlert showInView: self.view];
        
    } else {
        // Fix #627
        
        if (_allowCreatingContest) {
            _allowCreatingContest = NO;
            _createButton.userInteractionEnabled = NO;
            [self createContest];
        }
        
        
        
    }

    
}

- (void)dealloc {
    
    [[SDImageCache sharedImageCache] clearMemory];
}


- (void)photoImageViewTapped
{
    [self keyboardWillBeHidden];
    if ([self.view endEditing:YES]) {
        if ([self isPhotoLibraryAvailable]) {
            _imagePickerController = [[UIImagePickerController alloc] init];
            _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            _imagePickerController.mediaTypes = mediaTypes;
            _imagePickerController.allowsEditing = YES;
            _imagePickerController.delegate = self;
            [self presentViewController:_imagePickerController animated:YES completion:nil];
        }
    }
}



- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark - Request

- (void)createContest
{
   // if (![ECommon isNetworkAvailable]) return;
  
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPICreateContestPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:_titleTextField.text forKey:@"name"];
    [params setObject:_descriptionTextView.text forKey:@"description"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated: NO];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:@"data"];
            if (data) {
                contestInfo = [[NSMutableDictionary alloc] initWithDictionary:data];
                [self uploadContestPhotoWithContestId:[data valueForKey:@"id"]];
            } else {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
        } else {
            // Move to here to fix #636
            
            [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
            
            // Fix #627
            _createButton.userInteractionEnabled = YES;
            
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
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        DLog_Error(@"Error: %@", error);
        // Fix #627
        _createButton.userInteractionEnabled = YES;
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
}

- (void)uploadContestPhotoWithContestId:(NSString *)contestId
{
    //if (![ECommon isNetworkAvailable]) return;
   
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@", kAPIImageTypeContestCover, [NSString stringWithFormat:@"%@", contestId]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.6);
    //    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    //    [parameters setValue:kAPIImageTypeContestCover forKey:@"entityName"];
    //    [parameters setValue:[NSString stringWithFormat:@"%@", contestId] forKey:@"recordId"];
    //
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //[formData appendPartWithFormData:[kAPIImageTypeContestCover dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", contestId] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:@"data"];
            [contestInfo setValue:[data valueForKey:@"image"] forKey:@"image"];
            
            if (listGroup.count > 0) {
                [self inviteGroupToContestWithContestId:contestId];
                [self enterContest];
            } else {
                // Fix #636
                [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
                // Fix #627
                _createButton.userInteractionEnabled = YES;
                [self enterContest];
                
                // Go to contest page
                //[self gotoContestPage];
            }
        } else {
#ifdef BUG_LOGGING_ENABLE
            if([EJSONHelper valueFromData:responseObject]) {
                NSString *dateString = [QSystemHelper UTCStringFromDate:[NSDate date]];
                [EJSONHelper logJSON:parameters toFile:[NSString stringWithFormat:@"Upload_Image_Params_[Create Contest]_%@.json", dateString]];
                [EJSONHelper logJSON:responseObject toFile:[NSString stringWithFormat:@"Upload_Image_Response_[Create Contest]_%@.json", dateString]];
            }
#endif
            // Fix #636
            [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
            
            // Fix #627
            _createButton.userInteractionEnabled = YES;
            
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        // Fix #627
        _createButton.userInteractionEnabled = YES;
        
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
    [operation start];
}

- (void)inviteGroupToContestWithContestId:(NSString *)contestId
{
    //if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIInviteToContestPath];
    
    NSString *groupIdArray = @"";
    for (NSDictionary *dict in listGroup) {
        NSInteger groupId = [[dict valueForKey:@"id"] integerValue];
        if (groupIdArray.length > 0) {
            groupIdArray = [groupIdArray stringByAppendingString:[NSString stringWithFormat:@",%ld", (long)groupId]];
        } else {
            groupIdArray = [groupIdArray stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)groupId]];
        }
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:contestId forKey:@"contestId"];
    [params setObject:groupIdArray forKey:@"groupIdArray"];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        // Fix #627
        _createButton.userInteractionEnabled = YES;
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            
            // Adjust badge number
            [[QNotificationHelper getInstance] resetBadgeForType:kInviteGroupJoinContestNotificationType];
            
//            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            EContestPageViewController *contestPageVC = (EContestPageViewController *)[sb instantiateViewControllerWithIdentifier:@"contestPageVC"];
//            contestPageVC.contestInfo = contestInfo;
//            [self.navigationController pushViewController:contestPageVC animated:YES];
           // [self gotoContestPage];
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
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        DLog_Error(@"Error: %@", error);
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
}


- (void)enterContest
{
   // if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    __typeof (self) __weak pSelf = self;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIJoinContestPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[contestInfo valueForKey:@"id"] forKey:@"contestId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated: NO];
    
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *dataDict = [responseObject objectForKey:kAPIResponseData];
            NSInteger recordID = [[dataDict objectForKey:@"id"] integerValue];
            
            NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
            NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];//
            NSString *contestID = [contestInfo valueForKey:@"id"];
            if (!IS_NOT_NULL(contestID)) {
                contestID = [contestInfo objectForKey: @"contestId"];
            }
            
            NSString *key = [NSString stringWithFormat: @"%@_joined_%@", username, contestID];
            [df setBool: YES forKey: key];
            [df synchronize];
            
            [self uploadImageWithRecordID:recordID];
        } else {
            
            __typeof (pSelf) __strong mySelf = pSelf;
            _count++;
            if (_count <= 3) {
                [mySelf enterContest];
                return;
            }
            
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
            else {
                [[QUIHelper getInstance] showServerErrorAlert];
            }
            
            [mySelf gotoContestPage];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        DLog_Error(@"Error: %@", error);
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}


- (void)uploadImageWithRecordID:(NSInteger)recordID
{
    //if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@", kAPIImageTypeContestPhoto, [NSNumber numberWithInteger:recordID]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.6);
    //NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    //[parameters setValue:kAPIImageTypeContestPhoto forKey:@"entityName"];
    //[parameters setValue:[NSNumber numberWithInteger:recordID] forKey:@"recordId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated: NO];
    
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //[formData appendPartWithFormData:[kAPIImageTypeContestPhoto dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", [NSNumber numberWithInteger:recordID]] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            
            // Go to contest page
            [self gotoContestPage];
            
            // Go back
//            NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
//            if (groupInfo != nil) {
//                ETabBarController *tabBar = (ETabBarController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
//                tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
//                [[QUIHelper getInstance] setRootViewController:tabBar];
//            } else {
//                ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
//                ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
//                [navigationVC setViewControllers:@[createGroupVC]];
//                [[QUIHelper getInstance] setRootViewController:navigationVC];
//            }
            
        } else {
#ifdef BUG_LOGGING_ENABLE
            if([EJSONHelper valueFromData:responseObject]) {
                NSString *dateString = [QSystemHelper UTCStringFromDate:[NSDate date]];
                [EJSONHelper logJSON:parameters toFile:[NSString stringWithFormat:@"Upload_Image_Params_[Join Contest]_%@.json", dateString]];
                [EJSONHelper logJSON:responseObject toFile:[NSString stringWithFormat:@"Upload_Image_Response_[Join Contest]_%@.json", dateString]];
            }
#endif
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView: self.view animated: NO];
        
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
    [operation start];
}



#pragma mark - Keyboard Control

- (void)keyboardWasShown
{
    //    [UIView animateWithDuration:0.3f animations:^{
    //        CGRect frame = _scrollView.frame;
    //        frame.origin.y = -55;
    //        _scrollView.frame = frame;
    //        CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height);
    //        [_scrollView setContentOffset:bottomOffset animated:YES];
    //    } completion:nil];
}

- (void)keyboardWillBeHidden
{
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = _scrollView.frame;
        frame.origin.y = 64;
        _scrollView.frame = frame;
    } completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated: YES completion: nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated: NO completion: nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    //CGSize size = CGSizeMake(kPhotoSize, kPhotoSize);
    
    //image = [ECommon resizeImage: image ToSize: size];
    
    currentSelectImage = image;
    didSelectPhoto = YES;
    _selectPhotoLabel.hidden = YES;
    _photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_photoImageView setImage:image];
    //[_photoImageView setImage: [UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width]];
    [self checkInputWithTitle:_titleTextField.text description:_descriptionTextView.text];
}



#pragma mark - RSKImageCropViewControllerDelegate

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{

    }];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect
{
    currentSelectImage = croppedImage;
    [controller dismissViewControllerAnimated:NO completion:^{
        if(_imagePickerController) {
            [_imagePickerController dismissViewControllerAnimated:NO completion:^{
                didSelectPhoto = YES;
                _selectPhotoLabel.hidden = YES;
                [_photoImageView setImage: [UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width]];
                [self checkInputWithTitle:_titleTextField.text description:_descriptionTextView.text];
            }];
        }
    }];
}


- (void)gotoContestPage {
    
//    // Go to contest page
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    EContestPageViewController *contestPageVC = (EContestPageViewController *)[sb instantiateViewControllerWithIdentifier:@"contestPageVC"];
//    contestPageVC.contestInfo = contestInfo;
//    [self.navigationController pushViewController:contestPageVC animated:YES];
    
    // Go back
    NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
    if (groupInfo != nil) {
        ETabBarController *tabBar = (ETabBarController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
        tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
        [[QUIHelper getInstance] setRootViewController:tabBar];
    } else {
        ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
        ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
        [navigationVC setViewControllers:@[createGroupVC]];
        [[QUIHelper getInstance] setRootViewController:navigationVC];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self keyboardWasShown];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_descriptionTextView becomeFirstResponder];
    
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *name = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self checkInputWithTitle:name description:_descriptionTextView.text];
    
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 25;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self checkInputWithTitle:@"" description:_descriptionTextView.text];
    return YES;
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self keyboardWasShown];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *description = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (![ECommon isStringEmpty:description]) {
        _descriptionTextField.hidden = YES;
    } else {
        _descriptionTextField.hidden = NO;
    }
    
    if (description.length > kDescriptionTextMaxLength) {
        return NO;
    }
    
    [self checkInputWithTitle:_titleTextField.text description:description];
    
    return YES;
}

#pragma mark - EInviteGroupViewControllerDelegate

- (void)inviteGroupDidSelectGroups:(NSArray *)groups
{
    [listGroup removeAllObjects];
    [listGroup addObjectsFromArray:groups];
    [self reloadListGroupLabel];
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
