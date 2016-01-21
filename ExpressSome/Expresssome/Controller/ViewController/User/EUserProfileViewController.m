//
//  EUserProfileViewController.m
//  Expresssome
//
//  Created by QuanDT on 07/15/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import "EUserProfileViewController.h"
#import "ELoginViewController.h"
#import "SendGrid.h"
#import "SendGridEmail.h"
#import "EFeedBackViewController.h"
#import "AppDelegate.h"

@interface EUserProfileViewController () <RSKImageCropViewControllerDelegate>
{
    UIImage *currentSelectImage;
    UIImagePickerController *_imagePickerController;
    BOOL scrollDirectionDetermined;
}
@end

@implementation EUserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (IS_IPHONE_4_OR_LESS) {
        
        CGRect navFrame = _navBar.frame;
        navFrame.size.height = 64;
        _navBar.frame = navFrame;
        
    }
    
    //CGRect navFrame = CGRectMake(0, 0, self.view.bounds.size.width, 64);
    //[_navBar setFrame:navFrame];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect frame = self.scrollView.frame;
    float tabbarHeight = self.tabBarController.tabBar.frame.size.height;
    frame.size.height = screenRect.size.height - frame.origin.y - tabbarHeight - 64;
    
    self.scrollView.frame = frame;
    self.scrollView.delegate = self;
    
    // Add gesture to profile image view
    _profileImageView.userInteractionEnabled = YES;
    
    // Display user data
    [self displayUserData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reset content size
    CGSize newSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.width + 300);
    self.scrollView.contentSize = newSize;
}

#pragma - UI Actions - 
- (IBAction)logout:(id)sender {
    // End editing
    [self.view endEditing:TRUE];
    
    // Show popup
    [self showPopup:YES];
}

- (IBAction)selectPhotoTapped:(id)sender {
    [self openPhotoLibrary];
}

- (IBAction)edit:(id)sender {
    [self openPhotoLibrary];
}

- (IBAction)yesButtonPopupHasTapped:(id)sender {
    // Hide popup
    [self showPopup:NO];
    
    // Logout
    [self logout];
}

- (IBAction)noButtonPopupHasTapped:(id)sender {
    // Hide popup
    [self showPopup:NO];
}

- (IBAction)feedBackButtonHasTapped:(id)sender {
//    SendGrid *sendgrid = [SendGrid apiUser:kSendGridUserName apiKey:kSendGridPassword];
//    
//    SendGridEmail *email = [[SendGridEmail alloc] init];
//    email.to = @"dangthequan@live.com";
//    email.from = [[EUserData getInstance] objectForKey:EMAIL_UD_KEY];
//    email.subject = @"Hello World";
//    email.html =  @"<h1>My first email through SendGrid</h1>";
//    email.text = @"My first email through SendGrid";
//    
//    [sendgrid sendWithWeb:email];
    
    EFeedBackViewController *feedBackVC = (EFeedBackViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"feedBackVC"];
    feedBackVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:feedBackVC animated:YES];
}


#pragma mark - Other Methods -
- (void)showPopup:(BOOL)show
{
    [UIView animateWithDuration:0.3f animations:^{
        _popupView.hidden = !show;
    } completion:nil];
}

- (void)displayUserData {
    // Display text
    NSMutableString *passwordStr = [[NSMutableString alloc] initWithString:[[EUserData getInstance] objectForKey:PASSWORD_UD_KEY]];
    for(NSInteger i = 0; i < passwordStr.length; i++) {
        [passwordStr replaceCharactersInRange:NSMakeRange(i, 1) withString:@"*"];
    }
    
    self.usernameTF.text = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
    self.passwordTF.text = passwordStr;
    self.emailTF.text = [[EUserData getInstance] objectForKey:EMAIL_UD_KEY];
    self.passwordTF.secureTextEntry = NO;
    
    // Display saved profile photo
    QSystemHelper *systemHelper = [QSystemHelper getInstance];
    NSString *cacheDir = [systemHelper cacheDirectory];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", kAvatarImagePath, [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]];
    NSString *fullPath = [cacheDir stringByAppendingPathComponent:filePath];
    UIImage *image = [systemHelper imageAtPath:fullPath];
    if(image != nil) {
        [self setProfileImage:image];
    }
}

- (void)setProfileImage:(UIImage *)image {
    // Resize image
    UIImage *resizeImage = [UIImage imageWithImage:image scaledToMax:_profileImageView.frame.size.width];
    _profileImageView.image = resizeImage;
    
//    // Adjust frame for profileImageView
//    CGRect newFrame = _profileImageView.frame;
//    newFrame.size.height = resizeImage.size.height;
//    _profileImageView.frame = newFrame;
//    
//    // Adjust frame for contentView
//    newFrame = _contentView.frame;
//    newFrame.origin.y = _profileImageView.frame.origin.y + _profileImageView.frame.size.height;
//    _contentView.frame = newFrame;
    
}

- (void)uploadProfilePhoto
{
    // Check network connection
    if (![[QNetHelper getInstance] isNetworkAvailable]) return;
    
    // Show loading progress
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill URL & params
    NSString *urlStr = [NSString stringWithFormat:@"%@%@%@", kAPIBaseUrl, kAPIUploadImagePath, [NSString stringWithFormat:@"?entityName=%@&recordId=%@",kAPIImageTypeUserAvatar, [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]]];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlStr]];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSData *imageData = UIImageJPEGRepresentation(currentSelectImage, 0.7);
//    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
//    [parameters setValue:kAPIImageTypeUserAvatar forKey:@"entityName"];
//    [parameters setValue:[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] forKey:@"recordId"];
//    
    // Make request
    AFHTTPRequestOperation *operation = [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        //[formData appendPartWithFormData:[kAPIImageTypeUserAvatar dataUsingEncoding:NSUTF8StringEncoding] name:@"entityName"];
        //[formData appendPartWithFormData:[[NSString stringWithFormat:@"%@", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]] dataUsingEncoding:NSUTF8StringEncoding] name:@"recordId"];
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            if([data objectForKey:@"image"] != nil && [data objectForKey:@"image"] != [NSNull null]) {
                NSString *imagePath = [data objectForKey:@"image"];
                if(imagePath.length > 0) {
                    // Set avatar path
                    [[EUserData getInstance] setObject:[ECommon resetNullValueToString:imagePath] forKey:AVATAR_PATH_UD_KEY];
                }
            }
            
            // Save profile photo in local
            QSystemHelper *systemHelper = [QSystemHelper getInstance];
            NSString *cacheDir = [systemHelper cacheDirectory];
            NSString *fileName = [NSString stringWithFormat:@"%@.png", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]];
            NSString *filePath = [cacheDir stringByAppendingPathComponent:kAvatarImagePath];
            BOOL success = [systemHelper saveImage:currentSelectImage withName:fileName ToPath:filePath];
            if(!success) {
                NSLog(@"%s Failed to save profile photo", __FUNCTION__);
            }
            
            // Set image after upload successfully
//            _profileImageView.image = currentSelectImage;
            [self setProfileImage:currentSelectImage];

        } else {
#ifdef BUG_LOGGING_ENABLE
            if([EJSONHelper valueFromData:responseObject]) {
                NSString *dateString = [QSystemHelper UTCStringFromDate:[NSDate date]];
                [EJSONHelper logJSON:parameters toFile:[NSString stringWithFormat:@"Upload_Image_Params_[User Profile]_%@.json", dateString]];
                [EJSONHelper logJSON:responseObject toFile:[NSString stringWithFormat:@"Upload_Image_Response_[User Profile]_%@.json", dateString]];
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

- (void)logout {
    // Check networking
    if(![[QNetHelper getInstance] isNetworkAvailable]) {
        return;
    }
    
    // Show loading progress
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill url
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPILogoutPath];
    
    // Make request
    QAPIManager *apiMgr = [QAPIManager getInstance];
    apiMgr.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiMgr.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    [apiMgr POST:urlStr params:nil completeWithBlock:^(id responseObject, NSError *error) {
        // Hide loading progress
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if(error == nil) { // No error
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                // Clear default data
                [[EUserData getInstance] clear];
                
                // Unregister push notifications
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate unregisterPushNotificationForApplication:[UIApplication sharedApplication]];
                //[((AppDelegate *)[UIApplication sharedApplication].delegate) ]
                
                // Do logging out
                ELoginViewController *loginVC = (ELoginViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"loginVC"];
                ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
                [navigationVC setViewControllers:@[loginVC]];
                [[QUIHelper getInstance] setRootViewController:navigationVC];
            }
            else {
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
        else { // Error has occurred
            DLog_Error(@"Error: %@", error);
            [[QUIHelper getInstance] showServerErrorAlert];
        }
    }];
}


- (void)openPhotoLibrary {
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


#pragma mark - UIStatusBar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    [self uploadProfilePhoto];
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
                // Upload profile photo
                [self uploadProfilePhoto];
            }];
        }
    }];
}

#pragma mark - Scroll View Delegate -
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    //if(scrollDirectionDetermined) {
//        CGPoint translation = [scrollView.panGestureRecognizer translationInView:self.view];
//        if(translation.y > 0) { // Detect scrolling down
//            //scrollDirectionDetermined = FALSE;
//            [self setTabBarVisible:NO animated:YES];
//        }
//        else {
//            //scrollDirectionDetermined = FALSE;
//            [self setTabBarVisible:YES animated:YES];
//        }
//    //}
//}

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    scrollDirectionDetermined = FALSE;
//}
//
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    scrollDirectionDetermined = TRUE;
//}


- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated {
    //if ([self tabBarIsVisible] == visible) return;
    
    // Change tabbar frame
    CGRect frame = self.tabBarController.tabBar.frame;
    CGFloat height = frame.size.height;
    CGFloat offsetY = (visible)? -height : height;
    
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        if ([self tabBarIsVisible] != visible) {
            self.tabBarController.tabBar.frame = CGRectOffset(frame, 0, offsetY);
        }
        
        // Adjust tableview frame
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect scrollViewFrame = self.scrollView.frame;
        float tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        if(visible) {
            scrollViewFrame.size.height = screenRect.size.height - scrollViewFrame.origin.y - tabbarHeight - 64;
        }
        else {
            scrollViewFrame.size.height = screenRect.size.height - scrollViewFrame.origin.y - tabbarHeight;            
        }
        self.scrollView.frame = scrollViewFrame;
        
        // Reset content size
        if([self tabBarIsVisible]) {
            CGSize newSize = self.contentView.frame.size;
            newSize.height += self.profileImageView.frame.size.height;
            newSize.height += 20;
            self.scrollView.contentSize = newSize;
        }
        else {
            self.scrollView.contentSize = [[UIScreen mainScreen] bounds].size;
        }
        
    }];
}

- (BOOL)tabBarIsVisible {
    return self.tabBarController.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return ![view isKindOfClass:[UIButton class]];
}

@end
