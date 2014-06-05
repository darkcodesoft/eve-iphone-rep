//
//  EVETableViewController.h
//  eve
//
//  Created by Teddy Moussignac on 4/4/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVETableViewController : UITableViewController
@property (nonatomic, strong) NSArray *collection;
@property ( nonatomic, strong ) NSString *queryKeyword;
@property ( nonatomic, strong ) NSString *queryTimestamp;
@property ( nonatomic, strong ) NSMutableDictionary *queryCity;

-( void )getCollection:(bool) reset;

-( void )refreshCollection;

-( void )updateCollection;
@end
