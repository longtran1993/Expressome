//
//  EMessagesCollectionViewCellOutgoing.m
//  Expressome
//
//  Created by Quan DT on 7/9/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//


#import "EMessagesCollectionViewCellOutgoing.h"

@implementation EMessagesCollectionViewCellOutgoing

#pragma mark - Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentRight;
    self.cellBottomLabel.textAlignment = NSTextAlignmentRight;
}

@end
