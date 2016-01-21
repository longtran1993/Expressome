//
//  EContestFeedViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/8/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EContestFeedViewController.h"
#import "ECreateContestViewController.h"
#import "ECommon.h"
#import "AFNetworking.h"
#import "EContestPageViewController.h"
#import "MBProgressHUD.h"
#import "EContestFeedCell.h"
#import "IQKeyboardReturnKeyHandler.h"
#import "SVPullToRefresh.h"
#import "Reachability.h"
#import "EContestVoteViewController.h"

#define kUnSawStatus 0
#define kSawStatus 1

#define kUnVotedStatus 0
#define kVotedStatus 1

@interface EContestFeedViewController ()
{
    AFHTTPRequestOperation *request;
    IQKeyboardReturnKeyHandler *returnKeyHandler;
    NSString *serverTime;
    BOOL hasMoreData;
    BOOL isLoading;
    NSInteger currentTableTag;
    BOOL isFirstTime;
    BOOL scrollDirectionDetermined;
}

@end

@implementation EContestFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    isFirstTime = TRUE;
    _tableData = [[NSMutableArray alloc] init];
    currentTableTag = kNewContestTableViewTag;
    _tableView.tag = kNewContestTableViewTag;
    
    [_segment setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:102.0/255.0 green:170.0/255.0 blue:140.0/255.0 alpha:1.0], NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeueCyr-Light" size:18.0f]} forState:UIControlStateNormal];
    
    returnKeyHandler = [[IQKeyboardReturnKeyHandler alloc] initWithViewController:self];
    [returnKeyHandler setLastTextFieldReturnKeyType:UIReturnKeyDone];
    returnKeyHandler.toolbarManageBehaviour = IQAutoToolbarByPosition;
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        weakSelf.pageNumber = 1;
        [weakSelf.tableData removeAllObjects];
        [weakSelf.tableView reloadData];
        [weakSelf getContestList];
        [weakSelf.tableView.pullToRefreshView stopAnimating];
        weakSelf.tableView.showsInfiniteScrolling = YES;
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf getContestList];
    }];
    
    _tableView.showsInfiniteScrolling = NO;
    _tableView.showsPullToRefresh = NO;
    
    // Fix #451: Resize table view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect frame = self.tableView.frame;
    float tabbarHeight = self.tabBarController.tabBar.frame.size.height;
    frame.size.height = screenRect.size.height - frame.origin.y - tabbarHeight - 64;
    self.tableView.frame = frame;
    
    // Print out authen token
    NSLog(@"AUTHEN TOKEN = %@", [[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY]);
    NSLog(@"USER ID = %@", [[EUserData getInstance] objectForKey:USER_ID_UD_KEY]);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
     [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Observer for contentSize change
    //[self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];
    
    [super viewWillAppear:animated];
    //if (_segment.selectedSegmentIndex == 0) {
        [_tableData removeAllObjects];
        [_tableView reloadData];
        _pageNumber = 1;
        
        [self getContestList];
    //}
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.tableView removeObserver:self forKeyPath:@"contentSize"];
    [super viewWillDisappear:animated];
}

#pragma mark - Action

- (IBAction)startContestButtonTapped:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ECreateContestViewController *createContestVC = [sb instantiateViewControllerWithIdentifier:@"createContestVC"];
    createContestVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:createContestVC animated:YES];
}

- (IBAction)segmentValueChanged:(id)sender {
    _pageNumber = 1;
    switch (_segment.selectedSegmentIndex) {
        case 0: {
            _tableView.tag = kNewContestTableViewTag;
            currentTableTag = _tableView.tag;
        }
            break;
            
        case 1: {
            _tableView.tag = kOnGoingContestTableViewTag;
            currentTableTag = _tableView.tag;
        }
            break;
            
        case 2: {
            _tableView.tag = kResultsContestTableViewTag;
            currentTableTag = _tableView.tag;
        }
            break;
            
        default:
            break;
    }
    
    [_tableData removeAllObjects];
    [_tableView reloadData];
    [self getContestList];
}

- (NSComparisonResult)sortContestFeed:(NSDictionary *)contest {
    NSInteger joinStatus1 = [[((NSDictionary *)self) objectForKey:@"joinedStatus"] integerValue];
    NSInteger joinStatus2 = [[contest objectForKey:@"joinedStatus"] integerValue];
    if(joinStatus1 < joinStatus2) {
        return NSOrderedAscending;
    }
    else if(joinStatus1 > joinStatus2) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

- (void)setEnableState:(BOOL)enabled forCell:(EContestFeedCell *)cell
{
    cell.memberLabel.enabled = enabled;
    cell.contestName.enabled = enabled;
    cell.timeLabel.enabled = enabled;
    cell.joinLabel.enabled = enabled;
}

#pragma mark - Send request

- (void)getContestList
{
    // Fix #498
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
        
        NSString *apiPath = kAPIGetNewContestsContestPath;
        if(currentTableTag == kOnGoingContestTableViewTag) {
            apiPath = kAPIGetOnGoingContestPath;
        }
        else if(currentTableTag == kResultsContestTableViewTag) {
            apiPath = kAPIGetResultsContestPath;
        }
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, apiPath];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setValue:[NSNumber numberWithInteger:_pageNumber] forKey:@"page"];
        
        isLoading = YES;
        request = [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            isLoading = NO;
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                serverTime = nil;
                serverTime = [[NSString alloc] initWithString:[ECommon resetNullValueToString:[data valueForKey:@"currentTime"]]];
                
                NSArray *list = [data valueForKey:@"list"];
                
                NSDictionary *paginateDict = [data valueForKey:@"paginate"];
                _totalPage = [[paginateDict valueForKey:@"totalPage"] integerValue];
                _pageNumber = [[paginateDict valueForKey:@"currentPage"] integerValue];
                if (_pageNumber < _totalPage) {
                    hasMoreData = YES;
                    _tableView.showsInfiniteScrolling = YES;
                    _pageNumber++;
                } else {
                    hasMoreData = NO;
                    self.tableView.showsInfiniteScrolling = NO;
                }
                
                if (list && list.count > 0) {
                    NSInteger currentRow = [_tableData count];
                    [_tableData addObjectsFromArray:list];
                    
                    if(currentTableTag == kNewContestTableViewTag) {
                        NSSortDescriptor *joinDescriptor = [[NSSortDescriptor alloc] initWithKey:@"joinedStatus" ascending:YES];
                        NSArray *sortDescriptors = [NSArray arrayWithObject:joinDescriptor];
                        NSArray  *sortedArray = [_tableData sortedArrayUsingDescriptors:sortDescriptors];
                        _tableData = [[NSMutableArray alloc] initWithArray:sortedArray];
                        
                        if(_pageNumber == 1) {
                            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
                        }
                        else {
                            [_tableView reloadData];
                        }
                    }
//                    else if(currentTableTag == kOnGoingContestTableViewTag) {
////                        NSSortDescriptor *votedStatus = [[NSSortDescriptor alloc] initWithKey:@"votedStatus" ascending:YES];
//                        NSSortDescriptor *expireDate = [[NSSortDescriptor alloc] initWithKey:@"expiredDate" ascending:YES];
//                        NSArray *sortDescriptors = [NSArray arrayWithObjects:expireDate, nil];
//                        NSArray  *sortedArray = [_tableData sortedArrayUsingDescriptors:sortDescriptors];
//                        _tableData = [[NSMutableArray alloc] initWithArray:sortedArray];
//                        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
//                    }
                    else if(currentTableTag == kOnGoingContestTableViewTag){
                        if(_pageNumber == 1) {
                            [self reloadTableView:currentRow];
                        }
                        else {
                            [_tableView reloadData];
                        }
                    }
                    else if(currentTableTag == kResultsContestTableViewTag) {
                        // Fix #654: comment these below codes because sorting was implemented on server side
                        //                        NSSortDescriptor *votedStatus = [[NSSortDescriptor alloc] initWithKey:@"votedStatus" ascending:YES];
//                        NSSortDescriptor *expireDate = [[NSSortDescriptor alloc] initWithKey:@"expiredDate" ascending:NO];
//                        NSArray *sortDescriptors = [NSArray arrayWithObjects:expireDate, nil];
//                        NSArray  *sortedArray = [_tableData sortedArrayUsingDescriptors:sortDescriptors];
//                        _tableData = [[NSMutableArray alloc] initWithArray:sortedArray];
//                        
                        if(_pageNumber == 1) {
                            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                        }
                        else {
                            [_tableView reloadData];
                        }
                    }
                    
                    [self.tableView.infiniteScrollingView stopAnimating];

                    
                } else {
                    [_tableData removeAllObjects];
                    [_tableView reloadData];
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
            DLog_Error(@"Error: %@", error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [[QUIHelper getInstance] showServerErrorAlert];
            isLoading = NO;
        }];
    }
}

- (void)reloadTableView:(NSInteger)startingRow;
{
    // the last row after added new items
    NSInteger endingRow = [_tableData count];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (; startingRow < endingRow; startingRow++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:startingRow inSection:0]];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"contestFeedCell";
    
    EContestFeedCell *cell = (EContestFeedCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[EContestFeedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *dict = [_tableData objectAtIndex:indexPath.row];
    cell.serverTime = serverTime;
    [cell loadDataWithDict:dict andTableTag:tableView.tag];
    
    if(tableView.tag == kNewContestTableViewTag) {
        // Check joined status
        BOOL joined = [[dict objectForKey:@"joinedStatus"] boolValue];
        [self setEnableState:!joined forCell:cell];
        
        cell.joinLabel.text = @"Join";
    }
    else {
        if(tableView.tag == kOnGoingContestTableViewTag) {
            BOOL votedStatus = [[dict objectForKey:@"votedStatus"] boolValue];
            [self setEnableState:!votedStatus forCell:cell];
            
            NSInteger status = [[dict objectForKey:@"status"] integerValue];
            if(status == kRound1ContestType) {
                cell.joinLabel.text = @"Round 1";
            }
            else if(status == kRound2ContestType) {
                cell.joinLabel.text = @"Round 2";
            }
        }
        else if(tableView.tag == kResultsContestTableViewTag) {
            BOOL sawStatus = [[dict objectForKey:@"sawStatus"] boolValue];
            [self setEnableState:!sawStatus forCell:cell];
            cell.joinLabel.text = @"Results";
            
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [_tableData objectAtIndex:indexPath.row];
    
    if(tableView.tag == kNewContestTableViewTag) {
        // Fix #649: follow the customer's feedback
//        BOOL joined = [[dict objectForKey:@"joinedStatus"] boolValue];
//        if(!joined) {
            EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
            contestPageVC.contestInfo = dict;
            contestPageVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:contestPageVC animated:YES];
//        }
//        else {
//            UIAlertView* _alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have already joined this contest." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//            [_alert show];
//        }
    }
    else if(tableView.tag == kOnGoingContestTableViewTag) {
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = dict;
        contestVoteVC.contestType = kOnGoingContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
    }
    else if(tableView.tag == kResultsContestTableViewTag) {
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = dict;
        contestVoteVC.contestType = kResultContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
    }
}

- (void)scrollToBottom
{
    CGPoint bottomOffset = CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height);
    if ( bottomOffset.y > 0 ) {
        [_tableView setContentOffset:bottomOffset animated:YES];
    }
}
#pragma mark - EContestPageCellDelegate


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
        CGRect tblFrame = self.tableView.frame;
        float tabbarHeight = self.tabBarController.tabBar.frame.size.height;
        if(visible) {
            tblFrame.size.height = screenRect.size.height - tblFrame.origin.y - tabbarHeight - 64;
        }
        else {
            tblFrame.size.height = screenRect.size.height - tblFrame.origin.y - tabbarHeight;
        }
        self.tableView.frame = tblFrame;
    }];
}

- (BOOL)tabBarIsVisible {
    return self.tabBarController.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
}


#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}


#pragma mark - Key Value Observer -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    if(currentTableTag == kResultsContestTableViewTag) {
//        if ([keyPath isEqualToString:@"contentSize"]) {
//            NSValue *new = [change valueForKey:@"new"];
//            NSValue *old = [change valueForKey:@"old"];
//            
//            if (new && old) {
//                if (![old isEqualToValue:new]) {
//                    // Scroll to bottom
//                    if(_pageNumber > 2 && _pageNumber <= _totalPage) {
//                        [self scrollToBottom];
//                    }
//                    
//                }
//            }
//        }
//    }
}
@end
