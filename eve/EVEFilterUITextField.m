//
//  EVEFilterUITextField.m
//  eve
//
//  Created by Teddy Moussignac on 4/11/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEFilterUITextField.h"

@interface EVEFilterUITextField () <UITextFieldDelegate, UIPickerViewDelegate>

@end

@implementation EVEFilterUITextField

/** **/
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self draw];
    }
    return self;
}

/** **/
-( void ) draw
{
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 30)];
    self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.1];
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18];
    self.adjustsFontSizeToFitWidth = YES;
    self.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.leftView = paddingView;
    self.leftViewMode = UITextFieldViewModeAlways;
    self.clearsOnBeginEditing = NO;
}

/** **/
-( void ) drawPlaceholderInRect:(CGRect)rect
{
    [self.placeholder drawInRect:CGRectMake(0, 2, 260, 30) withAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:0 green:0 blue:0 alpha:.3],
                                                                              NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Thin" size:18]
                                                                              }];

}




@end
