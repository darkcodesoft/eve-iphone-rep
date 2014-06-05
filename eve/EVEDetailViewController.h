//
//  EVEDetailViewController.h
//  eve
//
//  Created by Teddy Moussignac on 5/18/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVEDetailViewController : UIViewController
@property ( nonatomic, strong ) NSString *id;
@property ( nonatomic, strong ) NSString *userId;
@property ( nonatomic, strong ) NSString *userName;
@property ( nonatomic, strong ) NSString *name;
@property ( nonatomic, strong ) NSString *startTtime;
@property ( nonatomic, strong ) NSString *endTime;
@property ( nonatomic, strong ) NSString *url;
@property ( nonatomic, strong ) NSString *admission;
//@property ( nonatomic, strong ) NSString *currency;
@property ( nonatomic, strong ) NSString *description;
@property ( nonatomic, strong ) NSArray *tags;
@property ( nonatomic, strong ) NSString *address;
//@property ( nonatomic, strong ) NSString *venue;
//@property ( nonatomic, strong  ) NSString *street;
//@property ( nonatomic, strong ) NSString *city;
//@property ( nonatomic, strong ) NSString *region;
//@property ( nonatomic, strong ) NSString *countryId;
//@property ( nonatomic, strong ) NSString *countryName;
//@property ( nonatomic, strong ) NSString *zipcode;
@property ( nonatomic, strong ) NSArray *going;
@property ( nonatomic, strong ) NSArray *images;
@property ( nonatomic ) float latitude;
@property ( nonatomic ) float longitude;
//@property ( nonatomic ) int visibility;
//@property ( nonatomic ) int created;
//@property ( nonatomic ) int privacy;
@property ( nonatomic ) int price;

-( void ) applyConfig:( NSDictionary *) config;

@end
