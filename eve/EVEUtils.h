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
#import "Reachability.h"

@interface EVEUtils : NSObject

@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, strong) NSUserDefaults *Defaults;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSMutableDictionary *theme;
@property (nonatomic, strong) Reachability *reach;
@property (nonatomic) NetworkStatus *netStatus;
@property (nonatomic) BOOL appIsOnline;
@property (nonatomic, strong) NSArray *startupCollection;

-( NSArray *) getCollectionforFeed:(NSString *) feedPath;

-( void ) initStartUpConfig: (id) App;

-( void ) initConfig;

-( void ) initSearch;

-( void ) locateUser;

-( void ) netWorkErrorHandler;

-( void ) initPostController:( UIViewController *) controller;

+( NSString *) parseTime:( int ) mins;

-( NSString *) parseUTCDate:( NSString *) utcDate;

-( NSString *) parseUTCDate:( NSString *) utcDate pattern:(NSString *) pattern;

-( NSString *) dateStringToUTC:( NSString *) dateString;

-( NSString *) getFeedWithConfig:( NSDictionary *) config;

-( NSString *) formatDate:( NSDate *) date pattern:(NSString *) pattern;

-( NSString *) dateToTimestamp:(NSDate *) date;

-( NSDate *) getNextWeekend;

-( NSDate *) utcToDate: ( NSString *) dateString;

- (bool) eveIsOnline;

-( int ) notificationsLength;

+( void ) alert:(NSString *)title message:(NSString *)message delegate:(id)delegate;

@end
