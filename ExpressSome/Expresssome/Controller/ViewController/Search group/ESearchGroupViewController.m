//
//  ESearchGroupViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ESearchGroupViewController.h"
#import "ESearchGroupCell.h"
#import "AFNetworking.h"
#import "EConstant.h"
#import "MBProgressHUD.h"
#import "ECommon.h"
#import "EGroupDetailViewController.h"
#import "SVPullToRefresh.h"

@interface ESearchGroupViewController ()
{
    AFHTTPRequestOperation *post;
    BOOL isLoading;
    BOOL keyboardShown;
    CGFloat keyboardOverlap;
    NSString *_lastSearchKeyword;
    NSInteger _totalPage;
}

@end

@implementation ESearchGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableData = [[NSMutableArray alloc] init];
    _lastSearchKeyword = @"";
    _totalPage = 1;
    _pageNumber = 0;
    
    _noResultLabel.hidden = YES;
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) { // Fix error same as #375
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect newFrame = self.tableView.frame;
        newFrame.size.height = screenRect.size.height - newFrame.origin.y - 64;
        self.tableView.frame = newFrame;
    }
    
    __weak typeof(self) weakSelf = self;
//    [self.tableView addPullToRefreshWithActionHandler:^{
////        weakSelf.pageNumber = 1;
////        [weakSelf.tableData removeAllObjects];
////        [weakSelf.tableView reloadData];
//        [weakSelf searchGroupWithKey:_seachTextField.text];
//        [weakSelf.tableView.pullToRefreshView stopAnimating];
//        weakSelf.tableView.showsInfiniteScrolling = YES;
//    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf searchGroupWithKey:_seachTextField.text];
    }];
    
    _tableView.showsInfiniteScrolling = NO;
    _tableView.showsPullToRefresh = NO;
    
    // Custom clear button
    UIButton *clearButton = [self.seachTextField valueForKey:@"_clearButton"];
    [clearButton setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    //[[SDImageCache sharedImageCache] clearMemory];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)closeKeyboard {
    [self.view endEditing:TRUE];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self closeKeyboard];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 50;
    if (y > h + reload_distance) {

    }
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if (keyboardShown) return;
    
    keyboardShown = YES;
    
    // Get the keyboard size
    UIScrollView *tableView;
    if ([self.tableView.superview isKindOfClass:[UIScrollView class]]) {
        tableView = (UIScrollView *)self.tableView.superview;
    } else {
        tableView = self.tableView;
    }
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if (self.inputAccessoryView && keyboardOverlap>0) {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
    if (keyboardOverlap < 0) {
        keyboardOverlap = 0;
    }
    
    if (keyboardOverlap != 0) {
        tableFrame.size.height -= keyboardOverlap;
        
        NSTimeInterval delay = 0;
        if(keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
        }
        
        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ tableView.frame = tableFrame; }
                         completion:^(BOOL finished){}];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (!keyboardShown) return;
    
    keyboardShown = NO;
    
    UIScrollView *tableView;
    if ([self.tableView.superview isKindOfClass:[UIScrollView class]]) {
        tableView = (UIScrollView *)self.tableView.superview;
    } else {
        tableView = self.tableView;
    }
    
    if (self.inputAccessoryView) {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    
    if (keyboardOverlap == 0) return;
    
    // Get the size & animation details of the keyboard
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    CGRect tableFrame = tableView.frame;
    tableFrame.size.height += keyboardOverlap;
    
    if(keyboardRect.size.height) {
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    }
    
    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ tableView.frame = tableFrame; }
                     completion:nil];
}

#pragma mark - Action

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Send request

- (void)searchGroupWithKey:(NSString *)key
{
    if (post) {
        [post cancel];
        post = nil;
    }
    
    __typeof (self) __weak pSelf = self;
    
    if ([ECommon isStringEmpty:key]) {
        self.tableView.showsInfiniteScrolling = NO;
        [_tableData removeAllObjects];
        [_tableView reloadData];
        _noResultLabel.hidden = NO;
        _lastSearchKeyword = key;
        [[SDImageCache sharedImageCache] clearMemory];
        return;
    }
    
    if (![ECommon isNetworkAvailable]) return;
    
    // Stop request when reach greater total page
    if(_pageNumber > _totalPage) {
        [pSelf.tableView.infiniteScrollingView stopAnimating];
        pSelf.tableView.showsInfiniteScrolling = NO;
        
        if (![key isEqualToString:_lastSearchKeyword]) {
            _pageNumber = 0;
            _totalPage = 1;
            [_tableData removeAllObjects];
            [_tableView reloadData];
        }
        return;
    }
    
    //if(isLoading == NO) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPISearchGroupPath];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setValue:key forKey:@"name"];
        [params setValue:[NSNumber numberWithInteger:_pageNumber] forKey:@"page"];
        
        isLoading = YES;
        post = [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            isLoading = NO;
            
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
                NSArray *list = [data valueForKey:@"list"];
                //__typeof (pSelf) __strong mySelf = pSelf;

                NSDictionary *paginateDict = [data valueForKey:@"paginate"];
                _totalPage = [[paginateDict valueForKey:@"totalPage"] integerValue];
                _pageNumber = [[paginateDict valueForKey:@"currentPage"] integerValue];
                if (_pageNumber < _totalPage) {
                    _tableView.showsInfiniteScrolling = YES;
                } else {
                    _tableView.showsInfiniteScrolling = NO;
                }
                
                _pageNumber++;
                
                if (![key isEqualToString:_lastSearchKeyword]) {
                    _pageNumber = 0;
                    _totalPage = 1;
                    [_tableData removeAllObjects];
                    [_tableView reloadData];
                }

                if (list && list.count > 0) {
                    for(NSDictionary *groupDict in list) {
                        NSInteger idValue = [[groupDict objectForKey:@"id"] integerValue];
                        BOOL isExisted = FALSE;
                        for(NSDictionary *groupDict2 in _tableData) {
                            NSInteger idValue2 = [[groupDict2 objectForKey:@"id"] integerValue];
                            if(idValue == idValue2) {
                                isExisted = TRUE;
                                break;
                            }
                        }
                        if(!isExisted) {
                            [_tableData addObject:groupDict];
                        }
                    }
                    //[_tableData addObjectsFromArray:list];
                    _noResultLabel.hidden = YES;
                    [_tableView reloadData];
                    [pSelf.tableView.infiniteScrollingView stopAnimating];
                } else {
                    if([_tableData count] <=0) {
                        _noResultLabel.hidden = NO;
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
            
            _lastSearchKeyword = key;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            isLoading = NO;
            DLog_Error(@"Error: %@", error);
            _lastSearchKeyword = key;
        }];
    //}
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

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self searchGroupWithKey:newString];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (post) {
        [post cancel];
        post = nil;
    }
    self.tableView.showsInfiniteScrolling = NO;
    [_tableData removeAllObjects];
    [_tableView reloadData];
    _noResultLabel.hidden = YES;
    _lastSearchKeyword = @"";
    [[SDImageCache sharedImageCache] clearMemory];

    return YES;
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
    static NSString *CellIdentifier = @"searchGroupCell";
    
    ESearchGroupCell *cell = (ESearchGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[ESearchGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [cell loadDataWithDict:[_tableData objectAtIndex:indexPath.row] andSearchedKey:_seachTextField.text];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EGroupDetailViewController *groupDetailVC = (EGroupDetailViewController *)[sb instantiateViewControllerWithIdentifier:@"groupDetailVC"];
    groupDetailVC.groupInfo = [_tableData objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:groupDetailVC animated:YES];
}


#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
