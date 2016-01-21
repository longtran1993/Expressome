//
//  ETabBarController.m
//  Expressome
//
//  Created by Dang Quan on 7/5/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "ETabBarController.h"

@interface ETabBarController ()

@end

@implementation ETabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set background
   // [self.tabBar setBackgroundImage:[UIImage imageNamed:@"tabbar_bgr"]];
    [self.tabBar setBackgroundColor:[UIColor colorWithRed:249.0/255.0 green:249.0/255.0 blue:249.0/255.0 alpha:1.0]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewWillLayoutSubviews
{
    CGRect tabFrame = self.tabBar.frame;
    NSLog(@"%d", tabFrame.height)
    tabFrame.size.height = 38;
    tabFrame.origin.y = self.view.frame.size.height - 38;
    self.tabBar.frame = tabFrame;
}

//- (CGSize)sizeThatFits:(CGSize)size
//{
//    
//    CGSize sizeThatFits = [super sizeThatFits:size];
//    sizeThatFits.height = 100;
//    
//    return sizeThatFits;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
