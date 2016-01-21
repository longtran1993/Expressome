//
//  EGroupMemberViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EGroupMemberViewController.h"
#import "MemberCollectionViewCell.h"
#import "ECommon.h"

@interface EGroupMemberViewController ()

@end

@implementation EGroupMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_isContestMember) {
        _titleLabel.text = [_contestInfo valueForKey:@"name"];
    } else {
        _titleLabel.text = [_groupInfo valueForKey:@"name"];
    }
    
    [_collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

#pragma mark - Action

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _listMember.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"memberCell";
    
    MemberCollectionViewCell *cell = (MemberCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    if (_isContestMember) {
        [cell setContestMemberDataWithDict:[_listMember objectAtIndex:indexPath.row]];
    } else {
        [cell setDataWithDict:[_listMember objectAtIndex:indexPath.row] adminId:[[ECommon resetNullValueToString:[_groupInfo valueForKey:@"admin"]] intValue]];
    }
    
    return cell;
}


@end
