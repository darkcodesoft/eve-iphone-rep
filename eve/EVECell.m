//
//  EVECell.m
//  eve
//
//  Created by Teddy Moussignac on 4/16/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVECell.h"

@implementation EVECell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Helpers
        NSLog(@"okay...");
    }
    
    return self;
}

-( void ) drawMe
{
    NSLog(@"I'm drawing...");
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
