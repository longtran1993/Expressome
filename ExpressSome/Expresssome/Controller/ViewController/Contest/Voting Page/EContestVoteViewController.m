//
//  EContestVoteViewController.m
//  Expressome
//
//  Created by Mr Lazy on 7/14/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EContestVoteViewController.h"
#import "VoteCollectionViewCell.h"
#import "TopVoteCollectionViewCell.h"
#import "EContestChatPageViewController.h"
#import "EGroupChatViewController.h"
#import "Reachability.h"
#import "UIImageView+WebCache.h"
#import "ECommon.h"
#import "EUserData.h"
#import "OKAlert.h"

#define kRound1Vote 1
#define kRound2Vote 1

#define kUnVotedStatus 0
#define kVotedStatus 1


#define kGoldPosition 0
#define kSilverPosition 1
#define kBronzePosition 2

#define kCallAPIVoteFromButtonBack      0
#define kCallAPIVoteFromButtonGroupChat 1

#define kGoFromBackButtonTag                0
#define kGoFromGroupChatButtonTag           1


#define kTopCellMargin  50

@interface EContestVoteViewController() <OKAlertDelegate>
{
    AFHTTPRequestOperation *request;
    NSArray *collectionData;
    
    BOOL isLoading;
    BOOL isSelectedDontShow;
    NSInteger showPopupFromButton;
    BOOL isVotedAtDevice;
    
    NSInteger currentID;
    NSInteger currentIndex;
    NSMutableDictionary *contestDetailsDict;
    BOOL isExpand;
    CGFloat minHeight;
    BOOL hasGotDetails;
}

@property (nonatomic, strong) OKAlert *okAlert;
@property (nonatomic, assign) BOOL allowVote;
@property (nonatomic, assign) BOOL count;

@end

@implementation EContestVoteViewController


#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    
    _count = 0;
    _allowVote = YES;
    isExpand = NO;
    hasGotDetails = FALSE;
    minHeight = 44.0f;
    
    // Fix #615 & #610
    _collectionView.alwaysBounceVertical = YES;
    
    // Fix #655 #660
    if(_contestType == kOnGoingContestType) {
        _chatButton.hidden = NO;
    }
    else {
        _chatButton.hidden = YES;
    }
    
    // Get detail contest
    [self getDetailContest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    currentIndex = -1;
    isVotedAtDevice = NO;
    
    if(hasGotDetails == YES) {
        [self getListImageContest];
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (collectionData.count + 1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    if (indexPath.row == 0) {
        cell = (TopVoteCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"topVoteContestCell" forIndexPath:indexPath];
        [self setupFirstCell:cell];
        
    } else {
         cell = (VoteCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"contestVoteCell" forIndexPath:indexPath];
        [self setUpCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        if (isExpand) {
            TopVoteCollectionViewCell *cell = (TopVoteCollectionViewCell*) [self.collectionView cellForItemAtIndexPath:indexPath];
            float rowHeight = 46 + [self calculatorDescriptionContest:cell];
            return CGSizeMake(CGRectGetWidth(self.view.frame), MAX(rowHeight, 90.0));
        } else {
            return CGSizeMake(CGRectGetWidth(self.view.frame), 90.0f);
        }
    }
    
    return CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame)+44);
}

#pragma mark - Action Handler

- (IBAction)backButtonTapped:(UIButton *)sender {
    
    if(_contestType == kResultContestType) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    
    if (sender.selected) {
        [self callVotePlayerFromButton:kGoFromBackButtonTag];
    } else {
        
        [self.navigationController popViewControllerAnimated:YES];
//        if (_contestType != kResultContestType) {
//            if (isVotedAtDevice) {
//                if([[[EUserData getInstance] objectForKey:DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY] boolValue]) {
//                    [self callVotePlayerFromButton:kGoFromBackButtonTag];
//                } else {
//                    [self showPopupChangeVote:YES from:kGoFromBackButtonTag];
//                }
//            } else {
//                [self.navigationController popViewControllerAnimated:YES];
//            }
//            
//        } else {
//            [self.navigationController popViewControllerAnimated:YES];
//        }

    }
    
}

- (IBAction)contestGroupChatButtonPressed:(id)sender
{
    // Show popup when when leave
    if (isVotedAtDevice) {
        if([[[EUserData getInstance] objectForKey:DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY] boolValue]) {
            [self callVotePlayerFromButton:kGoFromGroupChatButtonTag];
        } else {
            [self showPopupChangeVote:YES from:kGoFromGroupChatButtonTag];
        }
    } else {
        [self gotoGroupchat];
    }
}


- (IBAction)likeButtonPressed:(UIButton *)button
{
    
    if(_contestType == kResultContestType) {
        
        return;
    }
    
    if (!_allowVote) {
        return;
    }
    
    
    NSInteger index = button.tag -1;
    NSDictionary *dict = [collectionData objectAtIndex:index];
    NSInteger userId = [[dict objectForKey:@"userId"] integerValue];
    if([[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue] == userId) {
        
        return;
    }
    
    NSInteger status = 0;
    if (IS_NOT_NULL([_contestInfo objectForKey:@"status"])) {
        status = [[_contestInfo objectForKey:@"status"] integerValue];
    } else {
        status = [[_contestInfo objectForKey:@"round"] integerValue];
    }
    
    NSInteger tag = button.tag;
    button.selected = !button.selected;
    _btnBack.selected = button.selected;
    
    
    if (button.selected) {
        
        //_btnBack.selected = YES;
        //[_btnBack setBackgroundImage: nil forState: UIControlStateSelected];
        [_btnBack setImage:[UIImage imageNamed:@"btn_back_green.png"] forState:UIControlStateNormal];
//        [_btnBack setBackgroundImage: nil forState: UIControlStateNormal];
        //CGRect frame = _btnBack.frame;
        //frame.origin.x = -15;
        //_btnBack.frame = frame;
        if (!_okAlert) {
            _okAlert = [[OKAlert alloc] initWithDelegate: self];
        }
        ///////
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity: 0];
        
        for (int i=0; i< collectionData.count;  i++) {
            NSDictionary *dict = [collectionData objectAtIndex: i];
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary: dict];
            [tempDict setObject: @0 forKey: @"votedStatus"];
            [tempArray addObject: tempDict];
            
        }
        
        
        if (currentIndex != -1) {
            
            if (currentIndex != tag) {
                if(status == kRound1ContestType) {
                    NSMutableDictionary *tempDict = [tempArray objectAtIndex: currentIndex - 1];
                    NSInteger tempInt = [[tempDict valueForKey:@"round1Vote"] intValue] - 1;
                    if (tempInt < 0) {
                        tempInt = 0;
                    }
                    NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                    [tempDict setObject: tempStr forKey: @"round1Vote"];
                    
                }
                else if(status == kRound2ContestType) {
                    
                    NSMutableDictionary *tempDict = [tempArray objectAtIndex: currentIndex - 1];
                    NSInteger tempInt = [[tempDict valueForKey:@"round2Vote"] intValue] - 1;
                    if (tempInt < 0) {
                        tempInt = 0;
                    }
                    NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                    [tempDict setObject: tempStr forKey: @"round2Vote"];
                    
                }
                
                
            }
            
        }
        //////
        
        ////////////
        
        NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];//
        [tempDict setObject: @1 forKey: @"votedStatus"];
        
        if(status == kRound1ContestType) {
            NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
            NSInteger tempInt = [[tempDict valueForKey:@"round1Vote"] intValue] + 1;
            NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
            [tempDict setObject: tempStr forKey: @"round1Vote"];
            
        }
        else if(status == kRound2ContestType) {
            
            NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
            NSInteger tempInt = [[tempDict valueForKey:@"round2Vote"] intValue] + 1;
            NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
            [tempDict setObject: tempStr forKey: @"round2Vote"];
            
        }
        
        
        ///
        currentIndex = button.tag;
        /////////
        
        collectionData = tempArray;
        [self.collectionView reloadData];
        //////
        NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
        NSString *key = [NSString stringWithFormat: @"shw_cf_%@", username];
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        BOOL isShowedAlert = [[df objectForKey: key] boolValue];
        if (!isShowedAlert) {
            [_okAlert showInView: self.view];
            [df setObject: @YES forKey: key];
            [df synchronize];
        }
        
        
        
    } else {
        // unlike
        
        //CGRect frame = _btnBack.frame;
        //frame.origin.x = 5;
        //_btnBack.frame = frame;
        
        NSInteger tag = button.tag;
        
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity: 0];
        
        for (int i=0; i< collectionData.count;  i++) {
            NSDictionary *dict = [collectionData objectAtIndex: i];
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary: dict];
            [tempDict setObject: @0 forKey: @"votedStatus"];
            [tempArray addObject: tempDict];
            
        }
        
        if (currentIndex == -1) {
            NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];//
            [tempDict setObject: @0 forKey: @"votedStatus"];
        } else if (currentIndex != button.tag) {
            
            /////
            if (currentIndex != -1) {
                if(status == kRound1ContestType) {
                    NSMutableDictionary *tempDict = [tempArray objectAtIndex: currentIndex - 1];
                    NSInteger tempInt = [[tempDict valueForKey:@"round1Vote"] intValue] - 1;
                    if (tempInt < 0) {
                        tempInt = 0;
                    }
                    NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                    [tempDict setObject: tempStr forKey: @"round1Vote"];
                    
                }
                else if(status == kRound2ContestType) {
                    
                    NSMutableDictionary *tempDict = [tempArray objectAtIndex: currentIndex - 1];
                    NSInteger tempInt = [[tempDict valueForKey:@"round2Vote"] intValue] - 1;
                    if (tempInt < 0) {
                        tempInt = 0;
                    }
                    NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                    [tempDict setObject: tempStr forKey: @"round2Vote"];
                    
                }
            }
            //////
            
            
            
            
            
            NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];//
            [tempDict setObject: @1 forKey: @"votedStatus"];
            
            
            if(status == kRound1ContestType) {
                NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
                NSInteger tempInt = [[tempDict valueForKey:@"round1Vote"] intValue] + 1;
                NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                [tempDict setObject: tempStr forKey: @"round1Vote"];
                
            }
            else if(status == kRound2ContestType) {
                
                NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
                NSInteger tempInt = [[tempDict valueForKey:@"round2Vote"] intValue] + 1;
                NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                [tempDict setObject: tempStr forKey: @"round2Vote"];
                
            }
            
            
            currentIndex = button.tag;
        } else {
            NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];//
            [tempDict setObject: @0 forKey: @"votedStatus"];
            
            if(status == kRound1ContestType) {
                NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
                NSInteger tempInt = [[tempDict valueForKey:@"round1Vote"] intValue] - 1;
                if (tempInt < 0) {
                    tempInt = 0;
                }
                NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                [tempDict setObject: tempStr forKey: @"round1Vote"];
                
            }
            else if(status == kRound2ContestType) {
                
                NSMutableDictionary *tempDict = [tempArray objectAtIndex: tag - 1];
                NSInteger tempInt = [[tempDict valueForKey:@"round2Vote"] intValue] - 1;
                if (tempInt < 0) {
                    tempInt = 0;
                }
                NSString *tempStr = [NSString stringWithFormat:@"%d", tempInt];
                [tempDict setObject: tempStr forKey: @"round2Vote"];
                
            }
            
            currentIndex = -1;//test
        }
        
        //NSLog(@"currentIndex  %d", currentIndex);
        
        collectionData = tempArray;
        [self.collectionView reloadData];
        
        
    }
    
    if (!_btnBack.selected) {
        [_btnBack setImage:[UIImage imageNamed:@"btn_back_green.png"] forState:UIControlStateNormal];
        //[_btnBack setBackgroundImage: [UIImage imageNamed: @"btn_back_green.png"] forState: UIControlStateNormal];
    } else {
        [_btnBack setImage:[UIImage imageNamed:@"tick.png"] forState:UIControlStateNormal];

        //[_btnBack setBackgroundImage: nil forState: UIControlStateSelected];
        //[_btnBack setBackgroundImage: [UIImage imageNamed:@"tick.png"] forState: UIControlStateNormal];
    }
    
    NSDictionary *myDict = [collectionData objectAtIndex:(tag - 1)];
    currentID = [[myDict objectForKey:@"id"] integerValue];
    int d = 9;
    return;
    
    // If result contest
    if (_contestType == kResultContestType) {
        return;
    }
    
   // NSInteger tag = button.tag;
    
    if (currentIndex == -1) {
        // If have one player voted --> round voted.
        BOOL votedRound = [self votedAtContestRound];
        
        if (votedRound) {
            [self markAlreadyVotedAtIndex:tag];
            return;
        }
    }
    
    NSInteger previousIndex = currentIndex;
    dict = [collectionData objectAtIndex:(tag - 1)];
    currentID = [[dict objectForKey:@"id"] integerValue];
    currentIndex = tag - 1;
    
    if (currentIndex == previousIndex) {
        
        BOOL voted = [[dict objectForKey:@"votedStatus"] boolValue];
        [self vote:!voted forPlayerAtIndex:currentIndex];
    } else {
        if (previousIndex == -1) {
            BOOL canVote = [self canVotePlayerAtIndex:currentIndex];
            if (canVote) {
                [self vote:YES forPlayerAtIndex:currentIndex];
            } else {
                currentIndex = previousIndex;
            }
            
        } else {
            // Unvote for previous
            BOOL canVote = [self canVotePlayerAtIndex:currentIndex];
            if (canVote) {
                if (isVotedAtDevice) {
                    [self vote:NO forPlayerAtIndex:previousIndex];
                }
                // Vote for current player
                [self vote:YES forPlayerAtIndex:currentIndex];
            } else {
                currentIndex = previousIndex;
            }
        }
    }
}

- (void)handleLogicLike {
    
    
}

- (IBAction)yesButtonPopupHasTapped:(UIButton *)sender
{
    // Hide popup 2
    [self showPopupChangeVote:NO from:showPopupFromButton];
    
    [self callVotePlayerFromButton:showPopupFromButton];
}

- (IBAction)noButtonPopupHasTapped:(UIButton *)sender
{
    [self showPopupChangeVote:NO from:showPopupFromButton];
}

- (IBAction)stickButtonTapped:(UIButton *)sender {
    
    isSelectedDontShow = !isSelectedDontShow;
    if (isSelectedDontShow) {
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:YES] forKey:DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY];
        [_stickButton2 setImage:[UIImage imageNamed:@"stick_selected.png"] forState:UIControlStateNormal];
    } else {
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:NO] forKey:DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY];
        [_stickButton2 setImage:[UIImage imageNamed:@"stick_box.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)expandCollapseContent:(id)sender
{
    isExpand = !isExpand;
    
    [self.collectionView.collectionViewLayout invalidateLayout];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    TopVoteCollectionViewCell *__weak cell = (TopVoteCollectionViewCell*) [self.collectionView cellForItemAtIndexPath:indexPath]; // Avoid retain cycles
    
    // When expand description
    if (isExpand) {
        CGRect frame = cell.contestDescriptionTV.frame;
        frame.size.height = [self calculatorDescriptionContest:cell];
        CGRect cellFrame = cell.frame;
        cellFrame.size.height = [self calculatorDescriptionContest:cell] + 46;
        
        CGRect buttonFrame = cell.expandDescriptionButton.frame;
        buttonFrame.origin.y = cellFrame.size.height/2 - cell.expandDescriptionButton.frame.size.height/2;
        
        [UIView transitionWithView:cell.contentView duration:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.frame = cellFrame;
            cell.contestDescriptionTV.frame = frame;
            cell.contestDescriptionTV.text = [contestDetailsDict valueForKey:@"description"];
            cell.expandDescriptionButton.frame = buttonFrame;
            cell.expandDescriptionButton.transform = CGAffineTransformMakeRotation(M_PI);
            cell.contestDescriptionTV.textContainer.maximumNumberOfLines = 0;
            cell.contestDescriptionTV.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
            CGRect frame2 = cell.separator.frame;
            frame2.origin.y = 78;
           // cell.separator.frame = frame2;
        } completion:nil];
        
        // Collapase Description
    } else {
        CGRect cellFrame = cell.frame;
        cellFrame.size.height = 90;
        
        CGRect frame = cell.contestDescriptionTV.frame;
        //frame.origin.y = 42.0f;
        frame.size.height = minHeight;
        
        CGRect buttonFrame = cell.expandDescriptionButton.frame;
        buttonFrame.origin.y = cellFrame.size.height/2 - cell.expandDescriptionButton.frame.size.height/2;
        
        [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.frame = cellFrame;
            cell.contestDescriptionTV.frame = frame;
            cell.contestDescriptionTV.text = [contestDetailsDict valueForKey:@"description"];
            cell.expandDescriptionButton.frame = buttonFrame;
            cell.expandDescriptionButton.transform = CGAffineTransformMakeRotation(M_PI*2);
            cell.contestDescriptionTV.textContainer.maximumNumberOfLines = 2;
            cell.contestDescriptionTV.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
            CGRect frame2 = cell.separator.frame;
            frame2.origin.y = 306;
           // cell.separator.frame = frame2;
            
        } completion:nil];
    }
    
    [cell.contestDescriptionTV sizeToFit];
}

#pragma mark - Other Methods -

- (void)showPopupChangeVote:(BOOL)show from:(NSInteger)fromButton
{
    [UIView animateWithDuration:0.3f animations:^{
        _popupView2.hidden = !show;
    } completion:nil];
    
    showPopupFromButton = fromButton;
}


- (void)gotoGroupchat
{
    NSInteger status = 0;
    if (IS_NOT_NULL([_contestInfo objectForKey:@"status"])) {
        status = [[_contestInfo objectForKey:@"status"] integerValue];
    } else {
        status = [[_contestInfo objectForKey:@"round"] integerValue];
    }
    if(status == kRound1ContestType) {
        // Custom animation as push action
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromRight;
        [self.view.window.layer addAnimation:transition forKey:nil];
        
        // Go to group chat
        EGroupChatViewController *groupChatVC = (EGroupChatViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"groupChatVC"];
        
        groupChatVC.fromVotePage = TRUE;
        
        // Need to add groupChatVC intro navigation controller because we will need to navigate to other view controllers in Group Chat
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:groupChatVC];
        [self.navigationController presentViewController:navController animated:NO completion:nil];
    }
    else if(status == kRound2ContestType) {
        EContestChatPageViewController *contestChatPageVC = (EContestChatPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestChatPageVC"];
        contestChatPageVC.contestInfo =  self.contestInfo;
        contestChatPageVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestChatPageVC animated:YES];
    }
}

- (float)calculatorDescriptionContest:(TopVoteCollectionViewCell *)cell
{
    if (cell && contestDetailsDict) {
        NSString *text = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"description"]];
        if(text && text.length > 0) {
            UIFont *labelFont = cell.contestDescriptionTV.font;//[UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
            
            CGRect textRect = [text boundingRectWithSize:CGSizeMake(cell.contestDescriptionTV.frame.size.width, CGFLOAT_MAX)
                                                        options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                     attributes:@{ NSFontAttributeName : labelFont }
                                                        context:nil];
            
            CGSize textSize = CGRectIntegral(textRect).size;
            float newHeight = textSize.height+16;
            if(newHeight < minHeight) {
                return minHeight;
            }
            else return newHeight;
        }
    }
    
    return minHeight;
}

- (BOOL)isVoteAllowed {
    
    NSInteger result = NO;
    
    for (int i=0; i< collectionData.count;  i++) {
        NSDictionary *dict = [collectionData objectAtIndex: i];
        result = [[dict objectForKey: @"votedStatus"] integerValue];
        if (!result) continue;
        
        else break;
        
    }
    
    return !result;
}

#pragma mark - Send request

- (void)getListImageContest
{
    Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"No Internet Connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    else {
        if (isLoading) return;
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
        
        NSString *apiPath = kAPIGetListPlayerRound1;
        if(_contestType == kOnGoingContestType) {
            
            if (_openFromPush) {
                NSInteger status = [[_contestInfo objectForKey:@"round"] integerValue];
                if (status == kRound2ContestType) {
                    apiPath = kAPIGetListPlayerRound2;
                }
                
            } else {
                NSInteger status = [[_contestInfo objectForKey:@"status"] integerValue];
                if (!status) {
                    status = [[_contestInfo objectForKey:@"round"] integerValue];
                }
                if (status == kRound2ContestType) {
                    apiPath = kAPIGetListPlayerRound2;
                }
            }
            
        }
        else if(_contestType == kResultContestType) {
            apiPath = kAPIContestVoteResult;
        }
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, apiPath];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"id"]]) {
            [params setObject:[_contestInfo valueForKey:@"id"] forKey:@"contestId"];
        }
        else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestId"]]) {
            [params setObject:[_contestInfo valueForKey:@"contestId"] forKey:@"contestId"];
        }
        
        isLoading = YES;
        request = [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
            isLoading = NO;
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                NSArray *data = (NSArray *)[responseObject valueForKey:kAPIResponseData];
                collectionData = data;//[[NSMutableArray alloc] initWithArray:data];
                
                
                _allowVote = [self isVoteAllowed];
                [self.collectionView reloadData];
                
            } else {
                if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                    NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                    if(codeStatus == kAPI403ErrorCode) {
                        [[QUIHelper getInstance] showAlertLogoutMessage];
                    }
                    else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                        
                        NSString *message = [responseObject valueForKey:kAPIResponseMessage];
                        if ([message isEqualToString: @"This contest is not in round 2"]) {
                            [self getListImageContestResult];
                        } else {
                            [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                        }
                        
                    }
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [[QUIHelper getInstance] showServerErrorAlert];
            isLoading = NO;
        }];
    }
}


- (void)getListImageContestResult
{
    [_chatButton removeFromSuperview];
    _chatButton = nil;
    
    Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"No Internet Connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
    else {
        if (isLoading) return;
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
        
        NSString *apiPath = kAPIGetListPlayerRound1;
        apiPath = kAPIContestVoteResult;
        _contestType = kResultContestType;
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, apiPath];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"id"]]) {
            [params setObject:[_contestInfo valueForKey:@"id"] forKey:@"contestId"];
        }
        else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestId"]]) {
            [params setObject:[_contestInfo valueForKey:@"contestId"] forKey:@"contestId"];
        }
        
        isLoading = YES;
        request = [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            isLoading = NO;
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                NSArray *data = (NSArray *)[responseObject valueForKey:kAPIResponseData];
                collectionData = data;//[[NSMutableArray alloc] initWithArray:data];
                
                
                _allowVote = [self isVoteAllowed];
                [self.collectionView reloadData];
                
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
            [[QUIHelper getInstance] showServerErrorAlert];
            isLoading = NO;
        }];
    }
}


- (void)callVotePlayerFromButton:(NSInteger)callFromButon
{
    // Check networking
    if(![[QNetHelper getInstance] isNetworkAvailable]) {
        return;
    }
    
    // Show loading progress
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Fill url
    //NSInteger contestStatus = [[_contestInfo objectForKey:@"status"] integerValue];
    NSInteger contestStatus = 0;
    if (IS_NOT_NULL([_contestInfo objectForKey:@"status"])) {
        contestStatus = [[_contestInfo objectForKey:@"status"] integerValue];
    } else {
        contestStatus = [[_contestInfo objectForKey:@"round"] integerValue];
    }
    NSString *apiPath = kAPIContestVoteRound1;
    if(contestStatus == kRound2ContestType) {
        apiPath = kAPIContestVoteRound2;
    }
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, apiPath];
    
    // Fill params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSNumber numberWithInteger:currentID] forKey:@"playerId"];
    
    // Make request
    QAPIManager *apiMgr = [QAPIManager getInstance];
    apiMgr.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiMgr.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    [apiMgr GET:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        // Hide loading progress
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if(error == nil) { // No error
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                if (callFromButon == kCallAPIVoteFromButtonBack) {
                    [self.navigationController popViewControllerAnimated:YES];
                } else if (callFromButon == kCallAPIVoteFromButtonGroupChat) {
                    [self gotoGroupchat];
                }
                
                // Update vote symbol
//                NSIndexPath *idxPath = [NSIndexPath indexPathWithIndex:currentIndex];
                
                // lamnguyen comment
               /* NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[collectionData objectAtIndex:currentIndex]];
                if(contestStatus == kRound1ContestType) {
                    NSInteger round1Vote = [[dict objectForKey:@"round1Vote"] integerValue];
                    [dict setObject:[NSNumber numberWithInteger:round1Vote+1] forKey:@"round1Vote"];
                }
                else if(contestStatus == kRound2ContestType) {
                    NSInteger round2Vote = [[dict objectForKey:@"round2Vote"] integerValue];
                    [dict setObject:[NSNumber numberWithInteger:round2Vote+1] forKey:@"round2Vote"];
                }
                [dict setObject:[NSNumber numberWithInteger:kVotedStatus] forKey:@"votedStatus"];
                
                //[collectionData replaceObjectAtIndex:currentIndex withObject:dict];
                [collectionData setObject:dict atIndexedSubscript:currentIndex]; // Fix #596
                [self.collectionView reloadData];
                */
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.collectionView reloadItemsAtIndexPaths:@[idxPath]];
//                });
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

- (void)getDetailContest
{
    if(![[QNetHelper getInstance] isNetworkAvailable]) {
        return;
    }
    
    // Show loading progress
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    NSString *apiPath = kAPIGetContestDetailPath;
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, apiPath];
    
    // Fill params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    DLog_High(@"_contest info %@", _contestInfo);
    if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"id"]]) {
        NSNumber *contestId = [NSNumber numberWithInt:[[_contestInfo valueForKey:@"id"] intValue]];
        [params setObject:contestId forKey:@"id"];
    }
    else if([EJSONHelper valueFromData:[_contestInfo valueForKey:@"contestId"]]) {
        NSNumber *contestId = [NSNumber numberWithInt:[[_contestInfo valueForKey:@"contestId"] intValue]];
        [params setObject:contestId forKey:@"id"];
    }
    
    // Make request
    QAPIManager *apiMgr = [QAPIManager getInstance];
    apiMgr.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiMgr.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    [apiMgr GET:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        // Hide loading progress
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if(error == nil) { // No error
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                contestDetailsDict = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[responseObject objectForKey:kAPIResponseData]];
                // @quandt: Only for testing
                //[contestDetailsDict setObject:@"Content of notification is Time to vote! Round 1 of [contest's axdadlkajdkljadkljajadklaj dklajdklajdkljadkljaj kdss kdjskdjs kdjskdjs kdjskdjks kdjskdjsk kdsjdksj kdsjkds kdsjkds jdskdjsk dksjkdsj kdjskdjs dklajdkljadkljaj d klajdklajdklajsdklja" forKey:@"description"];
                
                _screenTitleLabel.text = [EJSONHelper valueFromData:[contestDetailsDict valueForKey:@"name"]] ? [contestDetailsDict valueForKey:@"name"] : @"";
                [self.collectionView reloadData];
                
                [self getListImageContest];
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
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}


#pragma mark - Setup Cell

- (void)setUpCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row -1;
    NSDictionary *dict = [collectionData objectAtIndex:index];
    VoteCollectionViewCell *cellSetup = (VoteCollectionViewCell *)cell;
    cellSetup.voteButton.selected = NO;
    
    cellSetup.voteButton.tag = indexPath.row;
    NSLog(@"Vote btn at index: %d", cellSetup.voteButton.tag);
    
    // Set frame for imageView
    CGRect newFrame = cellSetup.imageView.frame;
    newFrame.size.width = CGRectGetWidth(self.view.frame);
    newFrame.size.height = CGRectGetWidth(self.view.frame);
    cellSetup.imageView.frame = newFrame;
    // Set frame for info group
    newFrame = cellSetup.infoView.frame;
    newFrame.origin.y = CGRectGetWidth(self.view.frame);
    cellSetup.infoView.frame = newFrame;
    
    cellSetup.userImageView.layer.cornerRadius = cellSetup.userImageView.layer.frame.size.width/2;
    cellSetup.userImageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"userImage"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [cellSetup.userImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    } else {
        [cellSetup.userImageView setImage:[UIImage imageNamed:@"avatar.png"]];
    }
    
    // image
    imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [cellSetup.imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:nil options:0];
    } else {
        [cellSetup.imageView setImage:nil];
    }
    
    cellSetup.userNameLabel.text = [ECommon resetNullValueToString:[dict valueForKey:@"username"]];
    cellSetup.groupNameLabel.text = [ECommon resetNullValueToString:[dict valueForKey:@"groupName"]];
    
    // Detect vote button
    cellSetup.voteButton.tag = indexPath.row;
    NSInteger userId = [[dict objectForKey:@"userId"] integerValue];
    NSInteger status = 0;
    if (IS_NOT_NULL([_contestInfo objectForKey:@"status"])) {
        status = [[_contestInfo objectForKey:@"status"] integerValue];
    } else {
        status = [[_contestInfo objectForKey:@"round"] integerValue];
    }
    
    //NSInteger round1Vote = [[dict objectForKey:@"round1Vote"] integerValue];
    //NSInteger round2Vote = [[dict objectForKey:@"round2Vote"] integerValue];
    NSInteger votedStatus = [[dict objectForKey:@"votedStatus"] integerValue];
    
    if(_contestType == kOnGoingContestType) {
//        if([[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue] == userId) {
//            
//            [cellSetup.voteButton setImage:[UIImage imageNamed:@"normal_heart_symbol"] forState:UIControlStateNormal];
//        }
//        else {
//            if(votedStatus == kVotedStatus) {
//                [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_hightlight_heart_symbol"] forState:UIControlStateNormal];
//                if (!_btnBack.selected) {
//                    _allowVote = NO;
//                }
//            }
//            else {
//                [cellSetup.voteButton setImage:[UIImage imageNamed:@"hightlight_heart_symbol"] forState:UIControlStateNormal];
//            }
//        }
        

        if([[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue] == userId) {

            cellSetup.voteButton.selected = NO;
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"normal_heart_symbol"] forState:UIControlStateNormal];
        }
        else  if(votedStatus == kVotedStatus) {
    
            cellSetup.voteButton.selected = YES;
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_hightlight_heart_symbol"] forState:UIControlStateNormal];
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_hightlight_heart_symbol"] forState:UIControlStateSelected];
            
        }
        else {
            
            cellSetup.voteButton.selected = NO;
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"hightlight_heart_symbol"] forState:UIControlStateNormal];
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"hightlight_heart_symbol"] forState:UIControlStateSelected];
        }
        
        if(status == kRound1ContestType) {
            cellSetup.voteNumberLabel.text = [NSString stringWithFormat:@"%d",[[dict valueForKey:@"round1Vote"] intValue]];
        }
        else if(status == kRound2ContestType) {
            cellSetup.voteNumberLabel.text = [NSString stringWithFormat:@"%d",[[dict valueForKey:@"round2Vote"] intValue]];
        }

    }
    else if(_contestType == kResultContestType) {
        if(index == kGoldPosition) { // Gold
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_gold_heart_symbol"] forState:UIControlStateNormal];
        }
        else if(index == kSilverPosition) { // Silver
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_silver_heart_symbol"] forState:UIControlStateNormal];
        }
        else if(index == kBronzePosition) { // Bronze
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_bronze_heart_symbol"] forState:UIControlStateNormal];
        }
        else { // Normal
            [cellSetup.voteButton setImage:[UIImage imageNamed:@"fill_hightlight_heart_symbol"] forState:UIControlStateNormal];
        }
        
        cellSetup.voteNumberLabel.text = [NSString stringWithFormat:@"%d",[[dict valueForKey:@"round2Vote"] intValue]];
        
    }
    
//    if (indexPath.row == (collectionData.count - 1)) {
//        //CGRect separatorFrame = CGRectMake(kTopCellMargin, cellSetup.frame.size.height - 1, cellSetup.frame.size.width - (kTopCellMargin * 2), 1);
//        
//    }
    
//    UIImageView *imageView = [cellSetup viewWithTag: 100];
//    if (!indexPath.row) {
//        
//        imageView.alpha = 0;
//    } else {
//        imageView.alpha = 1;
//    }
    
    CGRect separatorFrame = CGRectMake(20, cellSetup.frame.size.height - 1, 279, 2);
    UIImageView *separator = [[UIImageView alloc] initWithFrame:separatorFrame];
    separator.image = [UIImage imageNamed: @"profile_line"];
    separator.tag = indexPath.row;
    
    [cellSetup addSubview:separator];

    
    _count++;
    
}

- (void)setupFirstCell:(UICollectionViewCell *)cell
{
    TopVoteCollectionViewCell *cellSetup = (TopVoteCollectionViewCell *)cell;
    cellSetup.contestOwerImageView.layer.cornerRadius = cellSetup.contestOwerImageView.frame.size.width / 2;
    cellSetup.contestOwerImageView.clipsToBounds = YES;
        
    NSString *imageStr = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"ownerImage"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [cellSetup.contestOwerImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    } else {
        [cellSetup.contestOwerImageView setImage:[UIImage imageNamed:@"avatar.png"]];
    }
    
    cellSetup.contestOwerLabel.text = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"ownerName"]];
    cellSetup.groupNameLabel.text = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"groupName"]];

    if(isExpand) {
        cellSetup.contestDescriptionTV.text = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"description"]];
        cellSetup.contestDescriptionTV.textContainer.maximumNumberOfLines = 0;
        cellSetup.contestDescriptionTV.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    }
    else {
        cellSetup.contestDescriptionTV.text = [ECommon resetNullValueToString:[contestDetailsDict valueForKey:@"description"]];//[self shortDescriptionText:[contestDetailsDict valueForKey:@"description"]];
        cellSetup.contestDescriptionTV.textContainer.maximumNumberOfLines = 2;
        cellSetup.contestDescriptionTV.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        cellSetup.contestDescriptionTV.textContainerInset = UIEdgeInsetsZero;
    }else {
        cellSetup.contestDescriptionTV.contentInset = UIEdgeInsetsMake(-11,-8,0,0);
    }
    //cellSetup.contestDescriptionTV.layer.borderWidth = 1.0f;
    
    if(!isExpand) {
        // When length description short, don't show expandButton
        if ([self calculatorDescriptionContest:cellSetup] <= minHeight) {
            cellSetup.expandDescriptionButton.hidden = YES;
        }
        else {
            cellSetup.expandDescriptionButton.hidden = NO;
        }
    }
    else {
        cellSetup.expandDescriptionButton.hidden = NO;
    }
    
   CGRect separatorFrame = CGRectMake(kTopCellMargin, cellSetup.frame.size.height - 1, cellSetup.frame.size.width - (kTopCellMargin * 2), 1);
    UIView *separator = [[UIView alloc] initWithFrame:separatorFrame];
//    separator.backgroundColor = [UIColor lightGrayColor];
//    [cellSetup addSubview:separator];
}

#pragma mark - Functions for vote

- (void)vote:(BOOL)vote forPlayerAtIndex:(NSInteger)index
{
    isVotedAtDevice = vote;
    // Increase vote
    NSInteger contestStatus = [[_contestInfo objectForKey:@"status"] integerValue];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[collectionData objectAtIndex:index]];
    
    if (vote) {
        if(contestStatus == kRound1ContestType) {
            NSInteger round1Vote = [[dict objectForKey:@"round1Vote"] integerValue];
            [dict setObject:[NSNumber numberWithInteger:round1Vote+1] forKey:@"round1Vote"];
        }
        else if(contestStatus == kRound2ContestType) {
            NSInteger round2Vote = [[dict objectForKey:@"round2Vote"] integerValue];
            [dict setObject:[NSNumber numberWithInteger:round2Vote+1] forKey:@"round2Vote"];
        }
        [dict setObject:[NSNumber numberWithInteger:kVotedStatus] forKey:@"votedStatus"];
    } else {
        if(contestStatus == kRound1ContestType) {
            NSInteger round1Vote = [[dict objectForKey:@"round1Vote"] integerValue];
            [dict setObject:[NSNumber numberWithInteger:round1Vote-1] forKey:@"round1Vote"];
        }
        else if(contestStatus == kRound2ContestType) {
            NSInteger round2Vote = [[dict objectForKey:@"round2Vote"] integerValue];
            [dict setObject:[NSNumber numberWithInteger:round2Vote-1] forKey:@"round2Vote"];
        }
        [dict setObject:[NSNumber numberWithInteger:kUnVotedStatus] forKey:@"votedStatus"];
    }
    
    //[collectionData replaceObjectAtIndex:currentIndex withObject:dict];
   // [collectionData setObject:dict atIndexedSubscript:index]; // Fix #596
    [self.collectionView reloadData];
}


// Check player voted for self
- (BOOL)canVotePlayerAtIndex:(NSInteger)index
{
    NSDictionary *dict = [collectionData objectAtIndex:(index)];
    
    // Get owner ID
    NSInteger userId = [[dict objectForKey:@"userId"] integerValue];
    
    BOOL canVote = TRUE;
    if([[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue] == userId) {
        canVote = FALSE;
    }
    
    return canVote;
}

// Check have voted round
- (BOOL)votedAtContestRound
{
    for (int i = 0; i < collectionData.count; i++) {
        NSDictionary *dict = [collectionData objectAtIndex:(i)];
        NSInteger votedStatus = [[dict objectForKey:@"votedStatus"] integerValue];
        
        // if exist one player voted by player --> voted at round
        if (votedStatus == kVotedStatus) {
            return TRUE;
        }
    }
    
    return FALSE;
}

- (void)markAlreadyVotedAtIndex:(NSInteger)idx
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(idx) inSection:0];
    VoteCollectionViewCell *__weak cell = (VoteCollectionViewCell*) [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alreadyVotedLabel.hidden = NO;
}

- (void)userDidTappedOK {
    
    
}

@end
