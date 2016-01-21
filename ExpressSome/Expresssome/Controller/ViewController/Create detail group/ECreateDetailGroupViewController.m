//
//  ECreateDetailGroupViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ECreateDetailGroupViewController.h"
#import "EConstant.h"
#import "ECommon.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "EGroupChatViewController.h"
#import "CoreData+MagicalRecord.h"
#import "EMessage.h"
#import "IQToolbar.h"

@interface ECreateDetailGroupViewController () <RSKImageCropViewControllerDelegate>
{
    BOOL didSelectPhoto;
    NSMutableDictionary *groupInfo;
    UIImage *currentSelectImage;
    UIImagePickerController *_imagePickerController;
}

@end

@implementation ECreateDetailGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
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
    
    [self checkInputWithGroupName:_nameTextField.text description:_descriptionTextView.text];
    
    // Custom clear button
    [[self.nameTextField valueForKey:@"_clearButton"] setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
    
    // Set placeholder for description textview
    self.descriptionTextView.placeholder = @"Add Group Description";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self keyboardWillBeHidden];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 576.0f)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)checkInputWithGroupName:(NSString *)groupName description:(NSString *)description
{
    if (didSelectPhoto == NO || [ECommon isStringEmpty:groupName] || [ECommon isStringEmpty:description]) {
        [_createButton setTitleColor:[UIColor colorWithRed:176.0f/255.0f green:174.0f/255.0f blue:183.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _createButton.enabled = NO;
        return NO;
    } else {
        [_createButton setTitleColor:[UIColor colorWithRed:121.0f/255.0f green:34.0f/255.0f blue:156.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _createButton.enabled = YES;
    }
    
    return YES;
}

#pragma mark - Others -

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

#pragma mark - Send request 

- (void)createGroup
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPICreateGroupPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:_nameTextField.text forKey:@"name"];
    [params setObject:_descriptionTextView.text forKey:@"description"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            NSNumber *groupId = [data valueForKey:@"id"];
            groupInfo = [[NSMutableDictionary alloc] initWithDictionary:data];
            [[NSUserDefaults standardUserDefaults] setObject:[groupInfo valueForKey:@"name"] forKey:@"currentGroupName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self uploadImageWithGroupId:groupId];
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog_Error(@"Error: %@", error);
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
}

- (void)uploadImageWithGroupId:(NSNumber *)groupId
{
    if (![ECommon isNetworkAvailable]) return;
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@", kAPIImageTypeGroupCover, [NSString stringWithFormat:@"%@", groupId]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.6);
//    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
//    [parameters setValue:@"group-cover" forKey:@"entityName"];
//    [parameters setValue:groupId forKey:@"recordId"];
//    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //[formData appendPartWithFormData:[kAPIImageTypeGroupCover dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", groupId] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {

            // Play notification sound
            [[QNotificationHelper getInstance] playNotificationSound];
            
            // Set group info to local
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            [groupInfo setValue:[data valueForKey:@"image"] forKey:@"image"];
            [[EUserData getInstance] setData:groupInfo forKey:GROUP_INFO_UD_KEY];
            
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UITabBarController *tabBar = [sb instantiateViewControllerWithIdentifier:@"tabbar"];
            //[tabBar.tabBar setBackgroundImage:[UIImage imageNamed:@"tabbar_bgr"]];
            tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:1];
            [self.navigationController presentViewController:tabBar animated:YES completion:nil];
            
        } else {
#ifdef BUG_LOGGING_ENABLE
            if([EJSONHelper valueFromData:responseObject]) {
                NSString *dateString = [QSystemHelper UTCStringFromDate:[NSDate date]];
                [EJSONHelper logJSON:parameters toFile:[NSString stringWithFormat:@"Upload_Image_Params_[Create Group]_%@.json", dateString]];
                [EJSONHelper logJSON:responseObject toFile:[NSString stringWithFormat:@"Upload_Image_Response_[Create Group]_%@.json", dateString]];
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
    [operation start];
}

#pragma mark - Keyboard Control

- (void)keyboardWasShown
{
//    [UIView animateWithDuration:0.3f animations:^{
//        CGRect frame = _scrollView.frame;
//        if (IS_IPHONE_4_OR_LESS) {
//            frame.origin.y = -120;
//        } else {
//            frame.origin.y = -120;
//        }
//        _scrollView.frame = frame;
//        
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
        [_scrollView scrollRectToVisible:CGRectMake(0.0f, 576.0f, 1.0f, 1.0) animated:YES];
    } completion:nil];
}

#pragma mark - Action

- (void)photoImageViewTapped
{
    [self.view endEditing:YES];
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

- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)createButtonTapped:(id)sender {
    [self createGroup];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    IQToolbar *toolbar = (IQToolbar*)[textField inputAccessoryView];
    [toolbar setTitle:@"Add Group Description"];
}
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
    [self checkInputWithGroupName:name description:_descriptionTextView.text];
    
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
    [self checkInputWithGroupName:@"" description:_descriptionTextView.text];
    return YES;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {

}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self keyboardWasShown];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *description = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (![ECommon isStringEmpty:description]) {
        _placeHolderTextField.hidden = YES;
    } else {
        _placeHolderTextField.hidden = NO;
    }
    
    if (description.length > kDescriptionMaxLength) {
        return NO;
    }
    
    [self checkInputWithGroupName:_nameTextField.text description:description];
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated: YES completion: nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated: NO completion: nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    CGSize size = CGSizeMake(kPhotoSize, kPhotoSize);
    
    image = [ECommon resizeImage: image ToSize: size];
    //image = [UIImage imageWithImage:currentSelectImage scaledToMax: 450.0];
    size = image.size;
    
    currentSelectImage = image;
    _selectPhotoLabel.hidden = YES;
    didSelectPhoto = YES;
    //_photoImageView.image = image;
    [_photoImageView setImage:[UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width]];
    [self checkInputWithGroupName:_nameTextField.text description:_descriptionTextView.text];
    
//    if(_imagePickerController) {
//        [_imagePickerController dismissViewControllerAnimated:NO completion:^{
//            _selectPhotoLabel.hidden = YES;
//            didSelectPhoto = YES;
//            [_photoImageView setImage:[UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width]];
//            [self checkInputWithGroupName:_nameTextField.text description:_descriptionTextView.text];
//        }];
//    }
    
}

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//    UIImage *image = info[UIImagePickerControllerOriginalImage];
//    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:image cropMode:RSKImageCropModeSquare];
//    imageCropVC.delegate = self;
//    imageCropVC.hidesBottomBarWhenPushed = TRUE;
//    [picker presentViewController:imageCropVC animated:YES completion:nil];
//}
//
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    [picker dismissViewControllerAnimated:YES completion:^(){
//    }];
//}

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
                _selectPhotoLabel.hidden = YES;
                didSelectPhoto = YES;
                [_photoImageView setImage:[UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width]];
                [self checkInputWithGroupName:_nameTextField.text description:_descriptionTextView.text];
            }];
        }
    }];
}


#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
