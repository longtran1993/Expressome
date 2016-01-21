//
//  EContestPageViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/11/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EContestPageViewController.h"
#import "ECommon.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "ESelectContestPhotoViewController.h"
#import "EContestFeedViewController.h"
#import "EMemberView.h"
#import "EGroupMemberViewController.h"

@interface EContestPageViewController ()
{
    NSMutableArray *memberList;
    BOOL hasJoined;
}

@end

@implementation EContestPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    hasJoined = [EJSONHelper valueFromData:[_contestInfo objectForKey:@"joinedStatus"]] ?[[_contestInfo objectForKey:@"joinedStatus"] boolValue] : false;
    _descriptionTextView.textAlignment = NSTextAlignmentJustified;
    _onwerPhotoImageView.layer.cornerRadius = _onwerPhotoImageView.frame.size.width / 2;
    _onwerPhotoImageView.clipsToBounds = YES;
    CGRect frame = _descriptionTextView.frame;
    frame.origin.y -= 4;
   /// _descriptionTextView.frame = frame;
    
    memberList = [[NSMutableArray alloc] init];
    [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width, 644.f)];
    
    [self initData];
    [self adjustViews];
    [self getContestDetail];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)initData
{
    if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"name"]]) {
        _screenTitleLabel.text = [_contestInfo valueForKey:@"name"];
    }
    else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestName"]]) {
        _screenTitleLabel.text = [_contestInfo valueForKey:@"contestName"];
    }
    else {
        _screenTitleLabel.text = @"";
    }
    
    _descriptionTextView.text = [ECommon resetNullValueToString:[_contestInfo valueForKey:@"description"]];
    NSString *imageStr = @"";
    if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"image"]]) {
        imageStr = [_contestInfo valueForKey:@"image"];
    }
    else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestImage"]]) {
        imageStr = [_contestInfo valueForKey:@"contestImage"];
    }
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_contestPhotoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            _contestPhotoImageView.image = image;
            //[self setContestPhoto:image];
        }];
    }
    else {
        _contestPhotoImageView.image = [UIImage imageNamed:@"group_defaul_icon.png"];
    }
    
    _ownerLabel.text = [ECommon resetNullValueToString:[_contestInfo valueForKey:@"ownerName"]];
    _groupNameLabel.text = [ECommon resetNullValueToString:[_contestInfo valueForKey:@"groupName"]];
    NSString *ownerImageStr = [ECommon resetNullValueToString:[_contestInfo valueForKey:@"ownerImage"]];
    if (ownerImageStr && ownerImageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, ownerImageStr];
        [_onwerPhotoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    }
    else {
        _onwerPhotoImageView.image = [UIImage imageNamed:@"avatar.png"];
    }
}

- (void)adjustViews { // Follow customer's feedback
    // Get main screen frame
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    float adjustHeight = mainFrame.size.height - self.memberView.frame.origin.y;
    
    // Set content size for scrollview
    if(adjustHeight > 0) {
        CGSize newSize = self.scrollView.contentSize;
        newSize.height += adjustHeight;
        self.scrollView.contentSize = newSize;
        
        // Adjust frame
        CGRect newFrame = self.memberView.frame;
        newFrame.origin.y = mainFrame.size.height;
        self.memberView.frame = newFrame;
        newFrame = self.bottomView.frame;
        newFrame.origin.y = self.memberView.frame.origin.y + self.memberView.frame.size.height;
        self.bottomView.frame = newFrame;
        newFrame = self.enterContestButton.frame;
        newFrame.origin.y = self.bottomView.frame.origin.y + self.bottomView.frame.size.height + 12;
        self.enterContestButton.frame = newFrame;
    }
    
    // Disable scrollable
    self.descriptionTextView.textAlignment = NSTextAlignmentJustified;
    //    self.descriptionTextView.scrollEnabled = YES;
    //
    //    // Adjust description textview
    //    CGFloat fixedWidth = _descriptionTextView.frame.size.width;
    //    CGSize newSize = [_descriptionTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    //    CGRect newFrame = _descriptionTextView.frame;
    //    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    //    _descriptionTextView.frame = newFrame;
    
    // Hide enterContestButton when user has joined the contest
//    BOOL joined = [[_contestInfo objectForKey:@"joinedStatus"] boolValue];
//    if(joined) {
//        // Hide button
//        self.enterContestButton.hidden = YES;
//        
//        // Change content size of scrollview
//        CGSize newSize = self.scrollView.contentSize;
//        newSize.height = newSize.height - (newSize.height - self.enterContestButton.frame.origin.y);
//        self.scrollView.contentSize = newSize;
//    }
}


- (void)setContestPhoto:(UIImage *)image { // Follow customer's feedback
    // Get main screen frame
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    
    UIImage *resizedImage = [UIImage imageWithImage:image scaledToWidth:_contestPhotoImageView.frame.size.width];
    _contestPhotoImageView.image = resizedImage;
    
    CGRect newFrame = _contestPhotoImageView.frame;
    newFrame.size.height = resizedImage.size.height;
    _contestPhotoImageView.frame = newFrame;
    
    // Set frame for imageHolderView
    newFrame = _imageHolderView.frame;
    newFrame.size.height = _imageHolderView.frame.origin.y + _contestPhotoImageView.frame.size.height;
    _imageHolderView.frame = newFrame;
    
    // Set frame for infoHolderView
    newFrame = _infoHolderView.frame;
    newFrame.origin.y = _imageHolderView.frame.origin.y + _imageHolderView.frame.size.height;
    _infoHolderView.frame = newFrame;
    
    // Set frame for descriptionHolderView
    newFrame = _descriptionHolderView.frame;
    newFrame.origin.y = _infoHolderView.frame.origin.y + _infoHolderView.frame.size.height;
    _descriptionHolderView.frame = newFrame;
    
    // Set frame for memberView
    newFrame = _memberView.frame;
    newFrame.origin.y = _descriptionHolderView.frame.origin.y + _descriptionHolderView.frame.size.height;
    _memberView.frame = newFrame;
    
    // Adjust memberView position
    float adjustHeight = mainFrame.size.height - _memberView.frame.origin.y;
    if(adjustHeight > 0) {
        
        // Adjust frame
        CGRect newFrame = _memberView.frame;
        newFrame.origin.y = mainFrame.size.height;
        _memberView.frame = newFrame;
    }
    
    // Set frame for bottomView
    newFrame = _bottomView.frame;
    newFrame.origin.y = _memberView.frame.origin.y + _memberView.frame.size.height;
    _bottomView.frame = newFrame;
    
    // Set frame for enterContestButton
    newFrame = _enterContestButton.frame;
    newFrame.origin.y = _bottomView.frame.origin.y + _bottomView.frame.size.height + 12;
    _enterContestButton.frame = newFrame;

    // Change content size of scrollview
    CGSize newSize = _scrollView.contentSize;
    // Hide enterContestButton when user has joined the contest
    BOOL joined = [[_contestInfo objectForKey:@"joinedStatus"] boolValue];
    if(joined) {
        // Hide button
        _enterContestButton.hidden = YES;
        newSize.height = _enterContestButton.frame.origin.y - 12;
    }
    else {
        newSize.height = _enterContestButton.frame.origin.y + _enterContestButton.frame.size.height + 12;

    }
    _scrollView.contentSize = newSize;
    
}

- (void)addMemberToView
{
    for (UIView *v in _bottomView.subviews) {
        if ([v isKindOfClass:[EMemberView class]]) {
            [v removeFromSuperview];
        }
    }
    
    if (memberList.count >= 4) {
        for (int i = 0; i < 4; i++) {
            EMemberView *memberView = (EMemberView *)[[[NSBundle mainBundle] loadNibNamed:@"EMemberView" owner:self options:nil] firstObject];
            memberView.frame = CGRectMake(i * 80.0f, 0.0f, 80.0f, 80.0f);
            [_bottomView addSubview:memberView];
            [memberView loadContestMemberDataWithDict:[memberList objectAtIndex:i]];
        }
    } else {
        for (int i = 0; i < memberList.count; i++) {
            EMemberView *memberView = (EMemberView *)[[[NSBundle mainBundle] loadNibNamed:@"EMemberView" owner:self options:nil] firstObject];
            memberView.frame = CGRectMake(i * 80.0f, 0.0f, 80.0f, 80.0f);
            [_bottomView addSubview:memberView];
            [memberView loadContestMemberDataWithDict:[memberList objectAtIndex:i] ];
        }
    }
}

#pragma mark - Action

- (IBAction)backButtonTapped:(id)sender {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[EContestFeedViewController class]]) {
            [self.navigationController popToViewController:vc animated:YES];
        } else {
            // Show tab bar
            [self.navigationController popViewControllerAnimated: NO];
            [self.tabBarController.tabBar setHidden:NO];
            [self.tabBarController setSelectedIndex:0];
            break;
        }
    }
}

- (IBAction)viewAllMemberButtonTapped:(id)sender {
    //if (memberList.count > 0) { // Comment to fix #535
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        EGroupMemberViewController *groupMemberVC = (EGroupMemberViewController *)[sb instantiateViewControllerWithIdentifier:@"groupMemberVC"];
        groupMemberVC.contestInfo = _contestInfo;
        groupMemberVC.listMember = memberList;
        groupMemberVC.isContestMember = YES;
        [self.navigationController pushViewController:groupMemberVC animated:YES];
    //}
}

- (IBAction)enterContestButtonTapped:(id)sender {
    if(!hasJoined) {
        ESelectContestPhotoViewController *selectContestPhotoVC = (ESelectContestPhotoViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"selectContestPhotoVC"];
        selectContestPhotoVC.contestInfo = _contestInfo;
        [self.navigationController pushViewController:selectContestPhotoVC animated:YES];
    }
    else {
        
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];//
        NSString *contestID = [_contestInfo objectForKey: @"id"];
        if (!IS_NOT_NULL(contestID)) {
            contestID = [_contestInfo objectForKey: @"contestId"];
        }
        
        NSString *key = [NSString stringWithFormat: @"%@_joined_%@", username, contestID];
        [df setBool: YES forKey: key];
        [df synchronize];
        
        UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have already entered this contest" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [_alert show];
    }

    
}



#pragma mark - Send request

- (void)getContestDetail
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIGetContestDetailPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"id"]]) {
        [params setObject:[_contestInfo valueForKey:@"id"] forKey:@"id"];
    }
    else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestId"]]) {
        [params setObject:[_contestInfo valueForKey:@"contestId"] forKey:@"id"];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            _contestInfo = [[NSDictionary alloc] initWithDictionary:data];
            [self initData];
            [self getContestMember];
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
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}

- (void)getContestMember
{
    if (![ECommon isNetworkAvailable]) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIMemberOfContestPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"id"]]) {
        [params setObject:[_contestInfo valueForKey:@"id"] forKey:@"contestId"];
    }
    else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestId"]]) {
        [params setObject:[_contestInfo valueForKey:@"contestId"] forKey:@"contestId"];
    }
    
    
    [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSArray *data = [responseObject valueForKey:@"data"];
            if (data && data.count > 0) {
                [memberList addObjectsFromArray:data];
                [self addMemberToView];
            }
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
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog_Error(@"Error: %@", error);
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}

- (void)enterContest
{
    if (![ECommon isNetworkAvailable]) return;
    
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
//            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            ESelectContestPhotoViewController *selectPhotoVC = (ESelectContestPhotoViewController *)[sb instantiateViewControllerWithIdentifier:@"selectContestPhotoVC"];
//            selectPhotoVC.contestInfo = _contestInfo;
//            [self.navigationController pushViewController:selectPhotoVC animated:YES];
            for (UIViewController *vc in self.navigationController.viewControllers) {
                if ([vc isKindOfClass:[EContestFeedViewController class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                }
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog_Error(@"Error: %@", error);
        //[[QUIHelper getInstance] showServerErrorAlert];
    }];
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
