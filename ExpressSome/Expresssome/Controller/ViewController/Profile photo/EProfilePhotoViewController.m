//
//  EProfilePhotoViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EProfilePhotoViewController.h"
#import "AFNetworking.h"
#import "EConstant.h"
#import "MBProgressHUD.h"
#import "ECommon.h"
#import "EConstant.h"

@interface EProfilePhotoViewController () <RSKImageCropViewControllerDelegate>
{
    BOOL didSelectPhoto;
    UIImage *currentSelectImage;
    UIImagePickerController *_imagePickerController;
}

@end

@implementation EProfilePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _skipbutton.hidden = NO;
    _doneButton.hidden = YES;
    _titleLabel.text = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
    
    _imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPhotoTapped:)];
    tapGesture.numberOfTapsRequired = 1;
    [_imageView addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)checkInput
{
    if (didSelectPhoto == NO) {
        [_doneButton setTitleColor:[UIColor colorWithRed:176.0f/255.0f green:174.0f/255.0f blue:183.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _doneButton.enabled = NO;
        return NO;
    } else {
        [_doneButton setTitleColor:[UIColor colorWithRed:121.0f/255.0f green:34.0f/255.0f blue:156.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _doneButton.enabled = YES;
    }
    
    return YES;
}

#pragma mark - Action

- (IBAction)skipButtonTapped:(id)sender {
    [self performSegueWithIdentifier:@"createGroupSegue" sender:self];
}

- (IBAction)doneButtonTapped:(id)sender {
    [self uploadImage];
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

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    _doneButton.hidden = NO;
    _skipbutton.hidden = YES;
    _imageView.image = [UIImage imageWithImage:currentSelectImage scaledToMax:_imageView.frame.size.width];
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
                _doneButton.hidden = NO;
                _skipbutton.hidden = YES;
                _imageView.image = [UIImage imageWithImage:currentSelectImage scaledToMax:_imageView.frame.size.width];
            }];
        }
    }];
}


#pragma mark - Send request

- (void)uploadImage
{
    if (![ECommon isNetworkAvailable]) return;
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@", kAPIImageTypeUserAvatar, [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.6);
    //    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    //    [parameters setValue:kAPIImageTypeUserAvatar forKey:@"entityName"];
    //    [parameters setValue:[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] forKey:@"recordId"];
    //
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //[formData appendPartWithFormData:[kAPIImageTypeUserAvatar dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            if (data) {
                [self performSegueWithIdentifier:@"createGroupSegue" sender:self];
                [[EUserData getInstance] setObject:[ECommon resetNullValueToString:[data valueForKey:@"image"]] forKey:AVATAR_PATH_UD_KEY];
                
                // Save profile photo to local
                QSystemHelper *systemHelper = [QSystemHelper getInstance];
                NSString *cacheDir = [systemHelper cacheDirectory];
                NSString *fileName = [NSString stringWithFormat:@"%@.png", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]];
                NSString *filePath = [cacheDir stringByAppendingPathComponent:kAvatarImagePath];
                BOOL success = [systemHelper saveFileWithName:fileName andData:imageData inPath:filePath];
                if(!success) {
                    NSLog(@"%s Failed to save profile photo", __FUNCTION__);
                }
                
                
            }
            
        } else {
#ifdef BUG_LOGGING_ENABLE
            if([EJSONHelper valueFromData:responseObject]) {
                NSString *dateString = [QSystemHelper UTCStringFromDate:[NSDate date]];
                [EJSONHelper logJSON:parameters toFile:[NSString stringWithFormat:@"Upload_Image_Params_[Profile Photo]_%@.json", dateString]];
                [EJSONHelper logJSON:responseObject toFile:[NSString stringWithFormat:@"Upload_Image_Response_[Profile Photo]_%@.json", dateString]];
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
