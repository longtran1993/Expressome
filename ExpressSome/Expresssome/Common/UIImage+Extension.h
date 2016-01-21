//
//  UIImage+Extension.h
//  Expressome
//
//  Created by Quan DT on 7/23/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)
+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToWidth:(float) width;
+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToMax:(float)max;
@end
