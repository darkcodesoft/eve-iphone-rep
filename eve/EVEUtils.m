//
//  EVEUtils.m
//  eve
//
//  Created by Teddy Moussignac on 4/5/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEUtils.h"
#import "EVEShareViewController.h"
#import "EVEUserViewController.h"
#import "Reachability.h"

@interface EVEUtils () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *ListSearchKeyWord;
@property (nonatomic, strong) NSString *MapSearchKeyWord;
@end

@implementation EVEUtils

/**
 * @initialize
 **/
-( instancetype ) init
{
    self = [super init];
    
    if( self )
    {
        _Defaults = [NSUserDefaults standardUserDefaults];
        [self initConfig];
    }
    
    return self;
}

/** **/
-( void ) initStartUpConfig: (id) App
{
    
}

/**
 * @desc get collection from server
 * @method setCollection
 **/
-( NSArray *) getCollectionforFeed:(NSString *)feedPath
{
    NSLog(@"%@", self.server);
    NSLog(@"%@", feedPath);
    NSArray *collection = [NSArray new];
    NSString *CString = [[NSString alloc] initWithFormat:@"%@%@", self.server, [feedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:CString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    
    
    [request setHTTPMethod: @"GET"];
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if( [data length] > 0 && error == nil )
    {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        
        if ([jsonObject isKindOfClass:[NSArray class]] )
        {
            NSArray *deserializedArray = jsonObject;
            collection = deserializedArray;
        }
        
        if([jsonObject isKindOfClass:[NSDictionary class]])
        {
            if( [jsonObject objectForKey:@"results"] )
            {
                NSDictionary *deserializedDictionary = jsonObject;
                NSArray *deserializedArray = deserializedDictionary[@"results"];
                collection = deserializedArray;
            }
            else
            {
                NSArray *result = [NSArray arrayWithObject:jsonObject];
                collection = result;
            }
        }
    }
    
    else if( [data length] == 0 )
    {
        NSLog(@"Response is empty.");
    }
    
    NSLog(@"********************");
    NSLog(@"%i", [collection count]);
    NSLog(@"********************");
    
    return collection;

}

/**
 * @desc UTC to Date String parser;
 **/
-( NSString *) parseUTCDate:(NSString *)utcDate pattern:(NSString *) pattern
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:locale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    NSDate *formattedDate = [dateFormatter dateFromString:utcDate];
    // reformat
    [dateFormatter setDateFormat:pattern];
    
    NSString *displayDate = [dateFormatter stringFromDate:formattedDate];
    
    return displayDate;
}

/** **/
-( NSString *) parseUTCDate:(NSString *)utcDate
{
    return [self parseUTCDate:utcDate pattern:@"EEEE MMM d, h:mm a"];
}

/** **/
-( NSString *) dateToTimestamp:(NSDate *) date
{
    return [NSString stringWithFormat:@"%f",[date timeIntervalSince1970] * 1000];
}

/** **/
-( NSString *) dateStringToUTC:(NSString *) dateString
{
    NSString *result = [NSString new];
    result = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"T"];
    // @todo the following causes app to crash
    result = [result stringByReplacingCharactersInRange:NSMakeRange(19, 1) withString:@"Z"];
    result = [result stringByReplacingCharactersInRange:NSMakeRange(20, 5) withString:@""];
    return result;
}

/** **/
-( NSDate *) getNextWeekend
{
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // Get the weekday component of the current date
    NSDateComponents *weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:today];
    
    /*
     Create a date components to represent the number of days to add to the current date.
     The weekday value for Friday in the Gregorian calendar is 6, so add the difference between 6 and today to get the number of days to add.
     Actually, on Saturday that will give you -1, so you want to subtract from 13 then take modulo 7
     */
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    [componentsToAdd setDay: (13 - [weekdayComponents weekday]) % 7];
    
    NSDate *friday = [gregorian dateByAddingComponents:componentsToAdd toDate:today options:0];
    
    /*
     friday now has the same hour, minute, and second as the original date (today).
     To normalize to midnight, extract the year, month, and day components and create a new date from those components.
     */
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                 fromDate: friday];
    
    // And to set the time to 20:00
    [components setHour:00];
    
    friday = [gregorian dateFromComponents:components];
    
    return friday;
}

/** **/
-( NSString *) formatDate:(NSDate *)date pattern:(NSString *) pattern
{
    // @"EEEE MMM d, YYYY"
    NSString *result = [self parseUTCDate:[self dateStringToUTC:[NSString stringWithFormat:@"%@", date]] pattern:pattern];
    
    return result;
}

/**
 *
 **/
-( NSString *) getFeedWithConfig:(NSDictionary *)config
{
//    NSString *feed = [[NSString alloc] init];
//    NSString *path = @"";
//    NSString *url = @"/api/q?";
//    NSString *city = [config valueForKey:@"city"];
//    NSString *region = [config valueForKey:@"region"];
//    NSString *country = [config valueForKey:@"country"];
//    NSString *keyword = [config valueForKey:@"keyword"];
//    NSString *startTime = [config valueForKey:@"startTime"];
//    // city
//    [self.Defaults setValue:city forKey:@"city"];
//    if( [[city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
//    {
//        path = [path stringByAppendingString: [NSString stringWithFormat:@"&city=%@", [city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
//    }
//    // region
//    [self.Defaults setValue:region forKey:@"region"];
//    if( [[region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
//    {
//        path = [path stringByAppendingString: [NSString stringWithFormat:@"&region=%@", [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
//    }
//    // country
//    [self.Defaults setValue:country forKey:@"country"];
//    if( [[country stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
//    {
//        path = [path stringByAppendingString: [NSString stringWithFormat:@"&countryName=%@", [country stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
//    }
//    if( [[keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
//    {
//        path = [path stringByAppendingString: [NSString stringWithFormat:@"&keyword=%@", [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
//    }
//    // startTime
//    if([[startTime stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
//    {
//        path = [path stringByAppendingString: [NSString stringWithFormat:@"&startTime=%@", [startTime stringByReplacingCharactersInRange:NSMakeRange(10, 10) withString:@""]]];
//    }
//
//    @try
//    {
//        path = [path stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:url];
//        feed = [[NSString stringWithFormat:@"%@&p=", path] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//    }
//    @catch( NSException *e )
//    {
//        NSLog(@"%@", e);
//    }
//    @finally
//    {
//        return feed;
//    }
    return @"";
}

/**
 * @desc
 * @method initConfig
 **/
-( void ) initConfig
{
    //self.server = @"http://192.168.1.7:3000";
    self.server = @"http://tp-eve.aws.af.cm";
    
    // TableViewController config
    NSMutableDictionary *tableViewControllerConfig = [[NSMutableDictionary alloc] init];
    [tableViewControllerConfig setValue:@"Search" forKey:@"title"];
    
    // MapViewController config
    NSMutableDictionary *mapViewControllerConfig = [[NSMutableDictionary alloc] init];
    [mapViewControllerConfig setValue:@"Nearby" forKey:@"title"];
    
    // PostViewController config
    NSMutableDictionary *PostViewControllerConfig = [[NSMutableDictionary alloc] init];
    [PostViewControllerConfig setValue:@"Post" forKey:@"title"];
    
    // UserViewController config
    NSMutableDictionary *UserViewControllerConfig = [[NSMutableDictionary alloc] init];
    [UserViewControllerConfig setValue:@"Calendar" forKey:@"title"];
    
    self.config = [[NSMutableDictionary alloc] init];
    [self.config setValue:tableViewControllerConfig forKey:@"ListConfig"];
    [self.config setValue:mapViewControllerConfig forKey:@"MapConfig"];
    [self.config setValue:PostViewControllerConfig forKey:@"PostConfig"];
    [self.config setValue:UserViewControllerConfig forKey:@"UserConfig"];
    
    // location Manager
    self.geocoder = [[CLGeocoder alloc] init];
    
    // set themne
    self.theme = [NSMutableDictionary new];
    [self.theme setValue:[UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f] forKey:@"themeColor"];
    [self.theme setValue:[UIColor whiteColor] forKey:@"menuFontColor"];
    
    //self.reach = [Reachability reachabilityWithHostname:self.server];
    
    self.reach = [Reachability reachabilityForInternetConnection];
    
    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationHandler)
                                                 name:@"Eve Event Reminder"
                                               object:nil];
    
}

-( void ) notificationHandler
{
    //[EVEUserViewController updateNotification];
}

- (bool) eveIsOnline
{
    bool res = NO;
    
    NetworkStatus network = [self.reach currentReachabilityStatus];
    
    if( network == NotReachable )
    {
        res = NO;
        [self.reach startNotifier];
    }
    else
    {
        res = YES;
    }
    
    return res;
}

-( void ) netWorkErrorHandler
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ooops... Network unvailable." message:@"Check your network then try again later." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    dispatch_after(1.0f, dispatch_get_main_queue(), ^(void){
        [alert show];
    });
}

-( NSDate *) utcToDate: ( NSString *) dateString
{
    //NSLog(@"%@", dateString);
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    NSDate *date = [[NSDate alloc] init];
    
    date = [df dateFromString: dateString];
    
    return date;
}

/**
 * @desc
 * @method initSearch
 **/
-( void ) initSearch
{
    //NSLog(@"Seach init.");
}

/** **/
-( void ) locateUser
{
    [self initLocationManager];
    [self.locationManager startUpdatingLocation];
}

/** **/
-( void ) initLocationManager
{
    if ([CLLocationManager locationServicesEnabled]){
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
    } else {
        /* Location services are not enabled.
         Take appropriate action: for instance, prompt the
         user to enable the location services */
        //NSLog(@"Location services are not enabled");
    }

}

// this delegate is called when the app successfully finds your current location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];

    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        //NSLog(@"Finding address");
        if (error) {
            NSLog(@"Error %@", error.description);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            [self.Defaults setObject:placemark.addressDictionary forKey:@"userAddress"];
            
            [self.locationManager stopUpdatingLocation];
            
            NSMutableDictionary *locationDictionary = [[NSMutableDictionary alloc] init];
            NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
            NSNumber *lon = [NSNumber numberWithDouble:location.coordinate.longitude];
            
            [locationDictionary setValue:lat forKeyPath:@"latitude"];
            [locationDictionary setValue:lon forKey:@"longitude"];
            [self.Defaults setValue:locationDictionary forKey:@"userLocation"];
        }
    }];
     
}

/** **/
-( void ) initPostController:(UIViewController *)controller
{
    EVEShareViewController *shareController = [[EVEShareViewController alloc] init];
    shareController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    shareController.delegate = controller;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:shareController];
    [controller presentViewController:navController animated:YES completion:^(void){
        
    }];
}

/** **/
+( NSString *) parseTime:( int ) mins;
{
    int hour = mins / 60;
    int min = mins % 60;
    int num_seconds = mins * 60;
    
    int days = num_seconds / (60 * 60 * 24);
    num_seconds -= days * (60 * 60 * 24);
    int hours = num_seconds / (60 * 60);
    num_seconds -= hours * (60 * 60);
    int minutes = num_seconds / 60;
    
    NSString *timeString = [NSString stringWithFormat:@"%i Mins", mins];
    
    if( mins > 60 )
    {
        timeString = [NSString stringWithFormat: @"%d Hrs %02d Mins", hours, min];
        
        if( hour > 24 )
        {
            timeString = [NSString stringWithFormat: @"%d Day %d Hrs %02d Mins", days, hours, minutes];
        }
    }
    
    return timeString;
}

/** **/
-( int ) notificationsLength
{
    return 2;
}

/** **/
+( void ) alert:(NSString *)title message:(NSString *)message delegate:(id)delegate
{
    id del = delegate ? delegate : self;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:del cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    dispatch_after(1.0f, dispatch_get_main_queue(), ^(void){
        [alert show];
    });
}

@end
