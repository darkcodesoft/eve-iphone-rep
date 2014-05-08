//
//  EVEUtils.h
//  eve
//
//  Created by Teddy Moussignac on 4/5/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>

@interface EVEUtils : NSObject

@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSUserDefaults *Defaults;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSMutableDictionary *theme;
@property (nonatomic) BOOL appIsOnline;

-( NSArray *) getCollectionforFeed:(NSString *) feedPath;

-( void ) initStartUpConfig: (id) App;

-( void ) initConfig;

-( void ) initSearch;

-( void ) locateUser;

-( void ) initPostController:( UIViewController *) controller;

-( NSString *) parseUTCDate:( NSString *) utcDate;

-( NSString *) parseUTCDate:( NSString *) utcDate pattern:(NSString *) pattern;

-( NSString *) dateStringToUTC:( NSString *) dateString;

-( NSString *) getFeedWithConfig:( NSDictionary *) config;

-( NSString *) formatDate:( NSDate *) date pattern:(NSString *) pattern;

-( NSString *) dateToTimestamp:(NSDate *) date;

-( NSDate *) getNextWeekend;

-(BOOL) eveIsOnline;

@end
