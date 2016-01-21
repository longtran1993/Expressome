//
//  EMessagesCollectionViewCellIncoming.m
//  Expressome
//
//  Created by Quan DT on 7/9/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EMessagesCollectionViewCellIncoming.h"

@implementation EMessagesCollectionViewCellIncoming

#pragma mark - Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentLeft;
    self.cellBottomLabel.textAlignment = NSTextAlignmentLeft;
}

@end
