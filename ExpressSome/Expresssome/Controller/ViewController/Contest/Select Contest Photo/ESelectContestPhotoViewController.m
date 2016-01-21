//
//  ESelectContestPhotoViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/12/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ESelectContestPhotoViewController.h"
#import "ECommon.h"
#import "AFNetworking.h"
#import "EContestFeedViewController.h"
#import "MBProgressHUD.h"
#import "ECreateGroupViewController.h"

@interface ESelectContestPhotoViewController () <RSKImageCropViewControllerDelegate>
{
    BOOL didSelectPhoto;
    UIImage *currentSelectImage;
    UIImagePickerController *_imagePickerController;
}

@end

@implementation ESelectContestPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _titleLabel.text = [_contestInfo valueForKey:@"name"];
    
    _photoImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhotoTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    [_photoImageView addGestureRecognizer:tapGesture];
    
    [self checkInput];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (BOOL)checkInput
{
    if (didSelectPhoto == NO) {
        [_enterContestButton setTitleColor:[UIColor colorWithRed:176.0f/255.0f green:174.0f/255.0f blue:183.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _enterContestButton.enabled = NO;
        return NO;
    } else {
        [_enterContestButton setTitleColor:[UIColor colorWithRed:121.0f/255.0f green:34.0f/255.0f blue:156.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _enterContestButton.enabled = YES;
    }
    
    return YES;
}

#pragma mark - Action

- (IBAction)enterContestButtonTapped:(id)sender {
    [self enterContest];
}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backToContestFeedPage
{
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[EContestFeedViewController class]]) {
            [self.navigationController popToViewController:vc animated:YES];
        }
    }
}

- (IBAction)selectPhotoTapped:(id)sender {
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

- (void)setImageForPhotoView:(UIImage *)image {
    UIImage *resizedImage = [UIImage imageWithImage:image scaledToMax:_photoImageView.frame.size.width];
    _photoImageView.image = resizedImage;
    
//    CGRect newFrame = _photoImageView.frame;
//    newFrame.size.height = resizedImage.size.height;
//    _photoImageView.frame = newFrame;
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
    
    currentSelectImage = image;
    didSelectPhoto = YES;
    _selectPhotoLabel.hidden = YES;
    _photoImageView.image = [UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width];
    [self checkInput];
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
                _photoImageView.image = [UIImage imageWithImage:currentSelectImage scaledToMax:_photoImageView.frame.size.width];
                [self checkInput];
            }];
        }
    }];
}

#pragma mark - Send request
- (void)enterContest
{
    if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIJoinContestPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[_contestInfo valueForKey:@"id"] forKey:@"contestId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *dataDict = [responseObject objectForKey:kAPIResponseData];
            NSInteger recordID = [[dataDict objectForKey:@"id"] integerValue];
            
            NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
            NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];//
            NSString *contestID = [_contestInfo valueForKey:@"id"];
            if (!IS_NOT_NULL(contestID)) {
                contestID = [_contestInfo objectForKey: @"contestId"];
            }
            
            NSString *key = [NSString stringWithFormat: @"%@_joined_%@", username, contestID];
            [df setBool: YES forKey: key];

            
            [self uploadImageWithRecordID:recordID];
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
            else {
                [[QUIHelper getInstance] showServerErrorAlert];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog_Error(@"Error: %@", error);
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}


- (void)uploadImageWithRecordID:(NSInteger)recordID
{
    if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@", kAPIImageTypeContestPhoto, [NSNumber numberWithInteger:recordID]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.6);
    //NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    //[parameters setValue:kAPIImageTypeContestPhoto forKey:@"entityName"];
    //[parameters setValue:[NSNumber numberWithInteger:recordID] forKey:@"recordId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //[formData appendPartWithFormData:[kAPIImageTypeContestPhoto dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", [NSNumber numberWithInteger:recordID]] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [[QUIHelper getInstance] showServerErrorAlert];
    }];
    [operation start];
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
