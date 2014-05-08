//
//  EVEMapSwitch.m
//  eve
//
//  Created by Teddy Moussignac on 5/6/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEMapSwitch.h"
#import "EVEUtils.h"

@interface EVEMapSwitch ()
@property (nonatomic, strong) EVEUtils *Utils;
@end

@implementation EVEMapSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initConfig];
    }
    return self;
}

-( void ) initConfig
{
    self.Utils = [EVEUtils new];
    
    [self setOn:YES];
    self.onTintColor = [self.Utils.theme valueForKey:@"themeColor"];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
