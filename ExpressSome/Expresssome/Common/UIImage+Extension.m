//
//  UIImage+Extension.m
//  Expressome
//
//  Created by Quan DT on 7/23/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)
+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToWidth: (float) width
{
    float oldWidth = sourceImage.size.width;
    float oldHeight = sourceImage.size.height;
    float scaleFactor = width / oldWidth;
    
    float newHeight = oldHeight * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(UIImage*)imageWithImage:(UIImage*) sourceImage scaledToMax:(float)max
{
    float oldWidth = sourceImage.size.width;
    float oldHeight = sourceImage.size.height;
    
    float scaleFactor = max / (oldWidth > oldHeight ? oldWidth : oldHeight);
    
    float newHeight = oldHeight * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
