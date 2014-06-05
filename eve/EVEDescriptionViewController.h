//
//  EVEDescriptionViewController.h
//  eve
//
//  Created by Teddy Moussignac on 4/19/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVEDescriptionViewController : UIViewController
@property (nonatomic, strong) NSString *headline;
@property (nonatomic, strong) NSString *subHeadline;
@property (nonatomic, strong) NSString *note;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *html;
@property (nonatomic, strong) id delegate;
@end
