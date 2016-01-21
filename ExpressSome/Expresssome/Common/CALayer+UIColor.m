//
//  CALayer+UIColor.m
//  Expressome
//
//  Created by Thien Liu on 11/5/15.
//  Copyright © 2015 Quan DT. All rights reserved.
//

#import "CALayer+UIColor.h"

@implementation CALayer(UIColor)

- (void)setBorderUIColor:(UIColor*)color {
    self.borderColor = color.CGColor;
}

- (UIColor*)borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}

@end
