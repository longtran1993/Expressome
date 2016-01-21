//
//  EGroupDetailViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EGroupDetailViewController.h"
#import "ECommon.h"
#import "EConstant.h"
#import "AFNetworking.h"
#import "EGroupChatViewController.h"
#import "MBProgressHUD.h"
#import "EGroupMemberViewController.h"
#import "EMemberView.h"
#import "ECreateGroupViewController.h"
#import "UIImageView+WebCache.h"
#import "CoreData+MagicalRecord.h"
#import "EMessage.h"

@interface EGroupDetailViewController ()
{
    NSMutableArray *listMember;
    BOOL didJoin;
    BOOL isSelectedDontShow;
    BOOL isOpenMenu;
}

@end

@implementation EGroupDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    listMember = [[NSMutableArray alloc] init];
    
    _leaveGroupView.hidden = YES;
    _descriptionTextView.backgroundColor = [UIColor clearColor];
    
    [self initData];
    [self getGroupMember];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    float contentHeight = self.groupPhotoImageView.bounds.size.height + self.infoView.bounds.size.height + self.bottomView.bounds.size.height;
    
    [_scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, contentHeight + 20)];
    //[_scrollView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    //_scrollView.alwaysBounceVertical = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}



- (void)initData
{
    _titleLabel.text = [ECommon resetNullValueToString:[_groupInfo valueForKey:@"name"]];
    _descriptionTextView.text = [ECommon resetNullValueToString:[_groupInfo valueForKey:@"description"]];
    
    NSString *imageStr = [ECommon resetNullValueToString:[_groupInfo valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_groupPhotoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
        [_groupPhotoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [self setGroupImage:image];
        }];
    }
}

- (void)setGroupImage:(UIImage *)image {
    // Get main screen frame
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    
    // Resize image
    UIImage *resizeImage = [UIImage imageWithImage:image scaledToWidth:_groupPhotoImageView.frame.size.width];
    _groupPhotoImageView.image = resizeImage;
    
    // Adjust frame for groupPhotoImageView
    CGRect newFrame = _groupPhotoImageView.frame;
    newFrame.size.height = resizeImage.size.height;
    _groupPhotoImageView.frame = newFrame;
    
    // Adjust frame for infoView
    newFrame = _infoView.frame;
    newFrame.origin.y = _groupPhotoImageView.frame.origin.y + _groupPhotoImageView.frame.size.height;
    _infoView.frame = newFrame;
    
    // Adjsut frame for bottomView
    newFrame = _bottomView.frame;
    newFrame.origin.y = _infoView.frame.origin.y + _infoView.frame.size.height;
   // _bottomView.frame = newFrame;
    
    // Fit bottom screen
    float  adjustHeight = mainFrame.size.height - (_bottomView.frame.origin.y + _bottomView.frame.size.height) - 64;
    if(adjustHeight > 0) {
        newFrame.origin.y += adjustHeight;
       // _bottomView.frame = newFrame;
    }
    
    // Adjust contentSize for scrollView
    CGSize newSize = _scrollView.contentSize;
    newSize.height = _bottomView.frame.origin.y + _bottomView.frame.size.height;
    _scrollView.contentSize = newSize;
    
}

- (void)addMemberToView
{
    for (UIView *v in _bottomView.subviews) {
        if ([v isKindOfClass:[EMemberView class]]) {
            [v removeFromSuperview];
        }
    }
    
    CGFloat marginTop = 25.0f;
    
    if (listMember.count >= 4) {
        for (int i = 0; i < 4; i++) {
            EMemberView *memberView = (EMemberView *)[[[NSBundle mainBundle] loadNibNamed:@"EMemberView" owner:self options:nil] firstObject];
            memberView.frame = CGRectMake(i * 80.0f, marginTop, 80.0f, 80.0f);
            memberView.backgroundColor = [UIColor clearColor];
            [_bottomView addSubview:memberView];
            [memberView loadDataWithDict:[listMember objectAtIndex:i] adminId:[[ECommon resetNullValueToString:[_groupInfo valueForKey:@"admin"]] intValue]];
        }
    } else {
        for (int i = 0; i < listMember.count; i++) {
            EMemberView *memberView = (EMemberView *)[[[NSBundle mainBundle] loadNibNamed:@"EMemberView" owner:self options:nil] firstObject];
            memberView.frame = CGRectMake(i * 80.0f, marginTop, 80.0f, 80.0f);
            memberView.backgroundColor = [UIColor clearColor];
            [_bottomView addSubview:memberView];
            [memberView loadDataWithDict:[listMember objectAtIndex:i] adminId:[[ECommon resetNullValueToString:[_groupInfo valueForKey:@"admin"]] intValue]];
        }
    }
}

- (void)showLeaveGroupView
{
    [UIView animateWithDuration:0.3f animations:^{
        _leaveGroupView.hidden = NO;
    } completion:nil];
}

- (void)hideLeaveGroupView
{
    [UIView animateWithDuration:0.3f animations:^{
        _leaveGroupView.hidden = YES;
    } completion:nil];
}

#pragma mark - Action

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated: NO];
}

- (IBAction)joinGroupButtonTapped:(id)sender {
    if (didJoin) {
//        if ([[[EUserData getInstance] objectForKey:DONT_SHOW_POPUP_UD_KEY] boolValue]) {
//            [self leaveGroup];
//        } else {
            [self showLeaveGroupView];
//        }
    } else {
        [self joinGroup];
    }
}

- (IBAction)viewAllButtonTapped:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EGroupMemberViewController *groupMemberVC = (EGroupMemberViewController *)[sb instantiateViewControllerWithIdentifier:@"groupMemberVC"];
    groupMemberVC.groupInfo = _groupInfo;
    groupMemberVC.listMember = listMember;
    [self.navigationController pushViewController:groupMemberVC animated:YES];
}

- (IBAction)leaveGroupYesButtonTapped:(id)sender {
    [self leaveGroup];
}

- (IBAction)leaveGroupNoButtonTapped:(id)sender {
    [self hideLeaveGroupView];
}

- (IBAction)stickButtonTapped:(id)sender {
    isSelectedDontShow = !isSelectedDontShow;
    if (isSelectedDontShow) {
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:YES] forKey:DONT_SHOW_POPUP_UD_KEY];
        [_stickButton setImage:[UIImage imageNamed:@"stick_selected.png"] forState:UIControlStateNormal];
    } else {
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:NO] forKey:DONT_SHOW_POPUP_UD_KEY];
        [_stickButton setImage:[UIImage imageNamed:@"stick_box.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)menuButtonTapped:(id)sender {
    isOpenMenu = !isOpenMenu;
    
    if (isOpenMenu) {
        [UIView animateWithDuration:0.3f animations:^{
            //CGRect frame = _menuView.frame;
            //frame.origin.y = 64;
            _menuView.hidden = NO;
            //_menuView.frame = frame;
           // [_menuButton setImage:[UIImage imageNamed:@"icon_menu_selected.png"] forState:UIControlStateNormal];
           // [_menuButton setFrame:CGRectMake(271.0f, 24.0f, 49.0f, 35.0f)];
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            //CGRect frame = _menuView.frame;
            //frame.origin.y = 64;
            _menuView.hidden = YES;
            //_menuView.frame = frame;
           // [_menuButton setImage:[UIImage imageNamed:@"icon_menu.png"] forState:UIControlStateNormal];
            //[_menuButton setFrame:CGRectMake(271.0f, 24.0f, 49.0f, 35.0f)];
        } completion:nil];
    }
}

#pragma mark - Send request

- (void)getGroupMember
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIGetGroupMemberPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[_groupInfo valueForKey:@"id"] forKey:@"groupId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSArray *data = [responseObject valueForKey:kAPIResponseData];
            [listMember removeAllObjects];
            if (data && data.count > 0) {
                [listMember addObjectsFromArray:data];
            }
            [self addMemberToView];
            
            BOOL isFound = NO;
            for (NSDictionary *member in listMember) {
                NSInteger currentUserId = [[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue];
                NSInteger userId = [[member valueForKey:@"id"] integerValue];
                if (currentUserId == userId) {
                    isFound = YES;
                    break;
                }
            }
            
            if (isFound) {
                didJoin = YES;
                CGPoint centerPoint = _joinButton.center;
                [_joinButton setImage:[UIImage imageNamed:@"btn_leave_group.png"] forState:UIControlStateNormal];
                [_joinButton setFrame:CGRectMake(10.0, 0.0f, 70.0f, 63.0f)];
                _joinButton.center = centerPoint;
                
                isOpenMenu = NO;
                //_menuView.frame = CGRectMake(0.0f, 65.0f, 320.0f, 63.0f);
                _menuView.hidden = YES;
                //[_menuButton setImage:[UIImage imageNamed:@"icon_menu.png"] forState:UIControlStateNormal];
               // [_menuButton setFrame:CGRectMake(271.0f, 24.0f, 49.0f, 35.0f)];
            } else {
                didJoin = NO;
                CGPoint centerPoint = _joinButton.center;
                [_joinButton setImage:[UIImage imageNamed:@"btn_join_group"] forState:UIControlStateNormal];
                [_joinButton setFrame:CGRectMake(10.0, 0.0f, 70.0f, 63.0f)];
                _joinButton.center = centerPoint;
                
                isOpenMenu = YES;
                //_menuView.frame = CGRectMake(0.0f, 65.0f, 320.0f, 63.0f);
                _menuView.hidden = NO;
               // [_menuButton setImage:[UIImage imageNamed:@"icon_menu_selected.png"] forState:UIControlStateNormal];
                //[_menuButton setFrame:CGRectMake(271.0f, 24.0f, 49.0f, 35.0f)];
            }
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
        
        
        if (listMember.count >= 50 && !didJoin) {
            _joinButton.enabled = NO;
        } else {
            _joinButton.enabled = YES;
        }
        
        if (listMember.count >= 50) {
            _memberLabel.text = @"FULL";
        } else {
            _memberLabel.text = [NSString stringWithFormat:@"%lu/50", (unsigned long)listMember.count];
        }
        
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog_Error(@"Error: %@", error);
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}

- (void)joinGroup
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIJoinGroupPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[_groupInfo valueForKey:@"id"] forKey:@"groupId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            
            // Set data
            [[EUserData getInstance] setData:_groupInfo forKey:GROUP_INFO_UD_KEY];
            [[EUserData getInstance] setObject:[NSNumber numberWithBool:TRUE] forKey:HAS_JUST_JOINED_GROUP_UD_KEY];
            
            [[NSUserDefaults standardUserDefaults] setObject:[_groupInfo valueForKey:@"name"] forKey:@"currentGroupName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UITabBarController *tabBar = [sb instantiateViewControllerWithIdentifier:@"tabbar"];
            //[tabBar.tabBar setBackgroundImage:[UIImage imageNamed:@"tabbar_bgr"]];
            tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:1];
            
            [self presentViewController:tabBar animated:YES completion:nil];
        } else {
            if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                if(codeStatus == kAPI403ErrorCode) {
                    [[QUIHelper getInstance] showAlertLogoutMessage];
                }
                else if(codeStatus == kAPI718ErrorCode) {
                    [[QUIHelper getInstance] showAlertWithMessage:@"This group have full members. You can't join group"];
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

- (void)leaveGroup
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPILeaveGroupPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[_groupInfo valueForKey:@"id"] forKey:@"groupId"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            
            // Remove group info from local
            [[EUserData getInstance] removeDataForKey:GROUP_INFO_UD_KEY];
            
            // Go to search group
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ECreateGroupViewController *createGroupVC = [sb instantiateViewControllerWithIdentifier:@"createGroupVC"];
            UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:createGroupVC];
            navi.navigationBarHidden = YES;
            [self presentViewController:navi animated:YES completion:nil];
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

#pragma mark - UIStatusBar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
