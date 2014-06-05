//
//  EVEMapViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/4/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//
const float filterViewHeight = 0;
static NSString *CellID = @"menu-table-cell";

#import "EVEMapViewController.h"
#import "EVEDetailViewController.h"
#import "EVEUtils.h"
#import "EVEAnnotation.h"
#import "EVEMapSwitch.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface EVEMapViewController () <CLLocationManagerDelegate,MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *header;
@property (nonatomic, strong) UILabel *subHeader;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSArray *filters;
@property (nonatomic, weak) IBOutlet UISegmentedControl *dateControl;
@property (nonatomic, weak) IBOutlet UIScrollView *dateControlScroll;
@property (nonatomic, weak) IBOutlet UIView *dateControlView;
@property (nonatomic, weak) IBOutlet UITableView *menuList;
@property (nonatomic, weak) IBOutlet UIView *menuListView;
@property (nonatomic, strong) EVEUtils *Utils;
@property (nonatomic, strong) NSString *feedURL;
@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSString *feed;
@property (nonatomic, weak) IBOutlet MKMapView *MapView;
@property (nonatomic, weak) IBOutlet UIView *filterView;
@property (nonatomic, weak) IBOutlet UIButton *localizeButton;
@property (nonatomic, weak) IBOutlet UIView *localizeViewWrap;
@property (nonatomic, weak) IBOutlet UISegmentedControl *timeControl;
@property (nonatomic, weak) IBOutlet UIView *screen;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, weak) IBOutlet UIView *distanceWrap;
@property (nonatomic, weak) IBOutlet UIImageView *distanceIcon;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;

@property (nonatomic, weak) IBOutlet UILabel *distanceLabel2;
@property (nonatomic, weak) IBOutlet UISlider *distanceSlider;
@property (nonatomic, weak) NSMutableArray *sliderValues;

@property (nonatomic) BOOL filterOpen;
@property (nonatomic) int set;
@property (nonatomic) int limit;
@property (nonatomic) int span;

@property (nonatomic, strong) NSString *queryLat;
@property (nonatomic, strong) NSString *queryLon;
@property (nonatomic, strong) NSString *queryTime;
@property (nonatomic ) int querySpan;

-( IBAction )dateControlSelected:(id)sender;

@end


@implementation EVEMapViewController

/** **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.Utils = [EVEUtils new];
    [self drawMap];
    [self initLocationManager];
    [self startTrackingUser];
    [self initTitleView];
    [self initConfig];
    [self drawFilter];
    
    // init listeners
    [self initListeners];
}

/** **/
-( void ) initConfig
{
    self.limit = 200;
    self.span = 5000;
    
    [self.spinner startAnimating];
    [self.spinner setAlpha:1];
    
    // distance slider
    [self initDistanceSlider];
    
    [self setQueryTime:[self.Utils formatDate:[NSDate date] pattern:@"yyyyMMddHHmmss" ]];
    [self setQuerySpan:10];
    self.distanceSlider.value = self.querySpan;
    [self.distanceLabel2 setText:[NSString stringWithFormat:@"%i Miles", self.querySpan]];

    // filterbutton
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleFilter)];
    self.navigationItem.rightBarButtonItem = filterButton;
}

/** **/
- (void)valueChanged:(UISlider*)sender
{
    int value = ( int )roundf( self.distanceSlider.value );
    [self.distanceLabel2 setText:[NSString stringWithFormat:@"%i %@", value, value < 2 ? @"Mile" : @"Miles"]];
    [self setQuerySpan:value];
    
    NSLog(@"%i", self.querySpan);
}

/** **/
-( void ) initDistanceSlider
{
    [self.distanceSlider addTarget:self
                            action:@selector(valueChanged:)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.distanceSlider setMaximumTrackTintColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.15]];
}

/** **/
-( void ) initTitleView
{
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 45)];
    self.header = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.titleView.bounds.size.width, 20)];
    self.header.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    self.header.textAlignment = NSTextAlignmentCenter;
    
    self.subHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.titleView.bounds.size.width, 20)];
    self.subHeader.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    self.subHeader.textAlignment = self.header.textAlignment = NSTextAlignmentCenter;
    self.subHeader.alpha = .7;
    
    self.header.textColor = self.subHeader.textColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    [self.titleView addSubview:self.header];
    [self.titleView addSubview:self.subHeader];
    
    [self setTitleViewLabel];
    
    self.navigationItem.titleView = self.titleView;
}

/** **/
-( void ) setTitleViewLabel
{
    self.header.text = [NSString stringWithFormat:@"%@, %@",
                        [[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"SubLocality"],
                        [[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"SubAdministrativeArea"]];
    
    self.subHeader.text = [NSString stringWithFormat:@"%@, %@",
                           [[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"City"],
                           [[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"State"]];
}

/** **/
-( void ) initListeners
{
    UITapGestureRecognizer *descTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startTrackingUser)];
    [self.localizeViewWrap addGestureRecognizer:descTap];
    
    UITapGestureRecognizer *titleViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleViewToggleFilter)];
    [self.titleView addGestureRecognizer:titleViewTap];
}

/** **/
-( void ) showDistanceView:(NSString *) distance
{
    [self.distanceLabel setText:distance];
    
    [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.distanceWrap setAlpha:1];
    } completion:nil];
}

/** **/
-( void ) hideDistanceView
{
    [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.distanceWrap setAlpha:0];
    } completion:nil];
}

/** **/
-( void ) drawDistanceView
{
    UIImage *image = [UIImage imageNamed:@"815-car-selected"];
    self.distanceIcon.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.distanceIcon setTintColor:[self.Utils.theme valueForKey:@"themeColor"]];
    
    self.distanceWrap.layer.cornerRadius = 5;
    self.distanceWrap.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.75];
    self.distanceLabel.textColor = [self.Utils.theme valueForKey:@"themeColor"];
}

/** **/
-( void ) drawLocalizeButton
{
    self.localizeViewWrap.layer.cornerRadius = 5;
    self.localizeViewWrap.backgroundColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    [self.localizeButton addTarget:self action:@selector(startTrackingUser) forControlEvents:UIControlEventTouchUpInside];
    [self.localizeButton setBackgroundImage:[UIImage imageNamed:@"701-location-1"] forState:UIControlStateNormal];
}

/** init post from Utils **/
-( void ) initPostController
{
    [self.Utils initPostController:self];
}

/** **/
-( void ) drawMap
{
    self.MapView.showsUserLocation = YES;
    [self.MapView setDelegate:self];
    [self drawLocalizeButton];
    [self drawDistanceView];
}

/** **/
-( void ) drawFilter
{
    self.filterOpen = NO;
    self.filterView.clipsToBounds = YES;
    [self.filterView setHidden:YES];

    self.dateControlScroll.contentSize = CGSizeMake( self.dateControl.bounds.size.width + 31, 40 );
    
    NSMutableDictionary *paid = [[NSMutableDictionary alloc] initWithDictionary:@{@"label" : @"Paid", @"id": @"paid", @"tags": @"paid", @"enable" : @YES}];
    NSMutableDictionary *ent = [[NSMutableDictionary alloc] initWithDictionary:@{@"label" : @"Entertainment", @"id": @"ent", @"tags": @"ent", @"enable" : @YES}];
    NSMutableDictionary *biz = [[NSMutableDictionary alloc] initWithDictionary:@{@"label" : @"Business", @"id": @"biz", @"tags": @"biz", @"enable" : @YES}];
    NSMutableDictionary *com = [[NSMutableDictionary alloc] initWithDictionary:@{@"label" : @"Community", @"id": @"com", @"tags": @"com", @"enable" : @YES}];
    NSMutableDictionary *edu = [[NSMutableDictionary alloc] initWithDictionary:@{@"label" : @"Education", @"id": @"edu", @"tags": @"edu", @"enable" : @YES}];
    
    self.filters = [NSArray arrayWithObjects: paid, ent, biz, com, edu, nil];
}

/** **/
-( void ) toggleFilter
{
    if( self.filterOpen ) [self hideFilter];
    else [self showFilter];
}

/** **/
-( void ) titleViewToggleFilter
{
    [self.titleView setAlpha:0.1];
    [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.titleView setAlpha:1.0];
    } completion:^(BOOL finished) {
        //Completion Block
    }];
    [self toggleFilter];
}

/** **/
-( void ) hideFilter
{
    self.filterOpen = NO;
    CGRect frame = [self.filterView frame];
    
    frame.origin.y = - self.filterView.frame.size.height + filterViewHeight;
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.filterView setFrame:frame];
    } completion:^(BOOL finished) {
        //Completion Block
        [self.filterView setHidden:YES];
        
        NSString *feed = [[NSString alloc] initWithFormat:@"/api/q?geo=true&lat=%@&long=%@&time=%@&limit=%i&span=%i", self.queryLat, self.queryLon, self.queryTime, self.limit, self.querySpan];
        @try {
            
            [self.filterView setFrame:frame];
            self.collection = [self.Utils getCollectionforFeed:feed];
            
            NSLog(@"Length: %i", [self.collection count]);
            
            [self setAnnotations];
        }
        @catch (NSException *exception) {
            NSLog(@"Error");
            [EVEUtils alert:@"Server unreachable." message:nil delegate:self];
        }
        @finally {
            nil;
        }
        
    }];
}

/** **/
-( void ) showFilter
{
    self.filterOpen = YES;
    CGRect frame = [self.filterView frame];
    
    frame.origin.y = filterViewHeight;
    [self.filterView setHidden:NO];
    [self.MapView removeOverlays:[self.MapView overlays]];
    [self hideDistanceView];
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.filterView setFrame:frame];
    } completion:^(BOOL finished) {
        //Completion Block
        [self.filterView setHidden:NO];
        [self.filterView setFrame:frame];
        self.querySpan = self.distanceSlider.value;
        self.queryTime = self.queryTime ? self.queryTime : @"";
        
        for( EVEAnnotation *anno in [self.MapView annotations])
        {
            if( [anno isKindOfClass:[EVEAnnotation class]] )
            {
                [UIView animateWithDuration:.3 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
                    //Animations
                    [self.filterView setFrame:frame];
                    [[self.MapView viewForAnnotation:anno] setAlpha:0];
                } completion:^(BOOL finished) {
                    //Completion Block
                    [[self.MapView viewForAnnotation:anno] setHidden:YES];
                }];
            }
        }
    }];
}

/** 
 *
**/
-( void ) setAnnotations
{
    for ( int i = 0; i < self.collection.count; i++ )
    {
        id object = [self.collection objectAtIndex:i];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[object valueForKey:@"latitude"] floatValue], [[object valueForKey:@"longitude"] floatValue]);
        EVEAnnotation *annotation =[[EVEAnnotation alloc] initWithTitle:[object valueForKey:@"name"] subTitle:[self.Utils parseUTCDate:[object valueForKey:@"startTime"] pattern:@"EEEE MMM d @ h:mm a"] location:location];
        annotation.config = object;
        [self.MapView addAnnotation: annotation];
//        [self addAnnotation:annotation];
    }
}

-( void ) addAnnotation:(EVEAnnotation *)annotation
{
    if( [self annotationIsEnable:annotation] ) [self.MapView addAnnotation: annotation];
}

-( bool ) annotationIsEnable:(EVEAnnotation *)annotation
{
    if( [self applyFilters:annotation] ) return YES;
    else return NO;
}

/** **/
-( bool ) applyFilters:(EVEAnnotation *)anno
{
    bool status = NO;
    for( NSMutableDictionary *filter in self.filters )
    {
        NSString *tag = [filter valueForKey:@"tags"];
        bool isEnable = [filter valueForKey:@"enable"];
        NSString *match = [NSString new];
        
        int count = 0;
//        
//        for( EVEAnnotation *anno in self.MapView.annotations )
//        {
//            count++;
        
            NSLog(@"%@", anno);
        
            bool (^selectedCase)() = @{
                                      @"paid" : ^{
                                          //NSLog(@"paid");
                                      },
                                      @"ent" : ^{
                                          //NSLog(@"ent");
                                      },
                                      @"biz" : ^{
                                          [self applyBizFilterToAnnoTation:anno indexPath:count];
                                          //NSLog(@"biz");
                                      },
                                      @"com" : ^{
                                          //NSLog(@"com");
                                      },
                                      @"edu" : ^{
                                          //NSLog(@"edu");
                                      },
                                      }[tag];
            
            if (selectedCase != nil) status = selectedCase();
//        }
    }
    
    return status;
}

/** **/
-( bool ) applyBizFilterToAnnoTation:(EVEAnnotation *) annotation indexPath:(int) path
{
    EVEAnnotation *anno = [self.MapView.annotations objectAtIndex:path-1];
    
    bool isEnable = [(NSMutableDictionary *)[self.filters objectAtIndex:path] valueForKey:@"enable"];
    NSString *pool = [[[anno.config valueForKey:@"tags"] componentsJoinedByString:@", "] lowercaseString];
    NSArray *matches = @[@"business",
                         @"class",
                         @"party",
                         ];
    
//    NSLog(@"%@", (NSMutableDictionary *)[self.filters objectAtIndex:path]);
//    NSLog(@"%@", anno.config);
    
    
    for( NSString *match in matches )
    {
        if( [pool rangeOfString:match].location != NSNotFound )
        {
//            [[self.MapView viewForAnnotation:anno] setHidden:isEnable]; // bug
//            NSLog(@"%@", [self.MapView viewForAnnotation:anno]);
//            NSLog(@"%d", isEnable);
//            NSLog(@"%@", annotation.config);
//            int64_t delayInSeconds = 1.0f;
//            
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//            
//            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[self.MapView viewForAnnotation:annotation] setHidden:isEnable]; // bug
                NSLog(@"%@", [self.MapView viewForAnnotation:annotation]);
                NSLog(@"%d", isEnable);
                NSLog(@"%@", annotation.config);
//            });
        }
    }
    
    return isEnable;
}

/**
 * @desc set collection for feed
 * @method getFeed:page:
 **/
-( void ) getFeed
{
    NSString *feed = [[NSString alloc] initWithFormat:@"/api/q?geo=true&lat=%@&long=%@&time=%@&limit=%i&span=%i", self.queryLat, self.queryLon, self.queryTime, self.limit, self.querySpan];
    @try {
        [self.MapView removeAnnotations:[self.MapView annotations]];
        self.collection = [self.Utils getCollectionforFeed:feed];
        [self setAnnotations];
    }
    @catch (NSException *exception) {
        NSLog(@"Error");
        [EVEUtils alert:@"Server unreachable." message:nil delegate:self];
    }
    @finally {
        nil;
    }
}

/** **/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** **/
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D location2d = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location2d, self.span, self.span);
    [self.MapView removeAnnotations:[self.MapView annotations]];
    [self.MapView setRegion:region animated:YES];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error) {
            NSLog(@"Error %@", error.description);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            [self.Utils.Defaults setObject:placemark.addressDictionary forKey:@"userAddress"];
            
            [self.locationManager stopUpdatingLocation];
            
            int64_t delayInSeconds = 1.0f;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                self.queryLat = [[self.Utils.Defaults objectForKey:@"userLocation"] valueForKey:@"latitude"];
                self.queryLon = [[self.Utils.Defaults objectForKey:@"userLocation"] valueForKey:@"longitude"];
                [self getFeed];
                [self.MapView addAnnotations:self.annotations];
            });
            
            NSMutableDictionary *locationDictionary = [[NSMutableDictionary alloc] init];
            NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
            NSNumber *lon = [NSNumber numberWithDouble:location.coordinate.longitude];
            
            [locationDictionary setValue:lat forKeyPath:@"latitude"];
            [locationDictionary setValue:lon forKey:@"longitude"];
            [self.Utils.Defaults setValue:locationDictionary forKey:@"userLocation"];
            [self setTitleViewLabel];
        }
    }];
}

/** **/
-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}

/** **/
-(int) initLocationManager
{
    if ([CLLocationManager locationServicesEnabled]){
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        return 1;
    } else {
        /* Location services are not enabled.
         Take appropriate action: for instance, prompt the
         user to enable the location services */
        NSLog(@"Location services are not enabled");
    }
    
    return 0;
}

/**
 * @desc start tracking user
 **/
-( void ) startTrackingUser
{
    if( self.locationManager )
    {
        [self.locationManager startUpdatingLocation];
    }
}

//
///** **/
-( void ) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    //NSLog(@"rendered.");
    [self.spinner stopAnimating];
    [UIView animateWithDuration:.6 delay:1.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.screen setAlpha:0];
    } completion:nil];
}
//
///** **/
//-( void ) mapViewDidFinishLoadingMap:(MKMapView *)mapView{
//
//}

/** 
 * @desc Use of custom annotation
 **/
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[EVEAnnotation class]]) // use whatever annotation class you used when creating the annotation
    {
        EVEAnnotation *myAnnotation = (EVEAnnotation *) annotation;
        myAnnotation.hasDetailView = YES;
        
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotation"];
        
        if( annotationView == nil )
        {
            annotationView = myAnnotation.annotationView;
        }
        else
        {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

/** 
 * @desc Annotation bubble tap handler
 **/
-( void ) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[EVEAnnotation class]])
    {
        // Navigation logic may go here, for example:
        // Create the next view controller.
        EVEAnnotation *viewAnno = view.annotation;
        
        EVEDetailViewController *itemViewController = [[EVEDetailViewController alloc] init];
        [itemViewController applyConfig: viewAnno.config];
        // Pass the selected object to the new view controller....
        
        // Push the view controller.
        itemViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:itemViewController animated:YES];
    }
}

/**
 * @desc AnnotationView focus handler
 **/
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView
{
    if( [annotationView.annotation isKindOfClass:[EVEAnnotation class]] )
    {
        [mapView removeOverlays:[mapView overlays]];

        MKPlacemark *destinationMark = [[MKPlacemark alloc] initWithCoordinate:annotationView.annotation.coordinate addressDictionary:nil];
        MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationMark];
        //
        [self findDirectionsFrom:destinationItem to:[MKMapItem mapItemForCurrentLocation]];
    }
}

/** 
 * @desc AnnotationView blur handler
 **/
-( void ) mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)annotationView
{
    if ([annotationView.annotation isKindOfClass:[EVEAnnotation class]])
    {
        [mapView removeOverlays:[mapView overlays]];
        [self hideDistanceView];
    }
}

/**
 * @desc Get Directions
 **/
- (void)findDirectionsFrom:(MKMapItem *)source to:(MKMapItem *)destination
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = source;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    request.destination = destination;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        //stop loading animation here
        
        if (error) {
            NSLog(@"Error is %@",error);
        } else {
            //do something about the response, like draw it on map
            MKRoute *route = [response.routes firstObject];
            [self.MapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
        }
    }];

    // calculate ETA
    MKDirections *directionss = [[MKDirections alloc] initWithRequest:request];
    [directionss calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
        
        int res = (int)ceil(response.expectedTravelTime/60.0);
        NSString *eta = @"UNAVAILABLE";
        
        if( res > 0 ) eta = [[EVEUtils parseTime:res] uppercaseString];

        [self showDistanceView:eta];
    }];
}

/** 
 * @desc draw direction lines
 **/
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    MKPolylineRenderer *polylineRender = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    polylineRender.lineWidth = 3;
    polylineRender.strokeColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:.75];
    return polylineRender;
}

/** **/
-( IBAction)dateControlSelected:(id)sender
{
    NSDate *date = [NSDate date];
    UISegmentedControl *s = (UISegmentedControl *)sender;
    long index = s.selectedSegmentIndex;
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    
    switch (index) {
        case 1:
            comps.day = 1;
            date = [cal dateByAddingComponents:comps toDate:date options:0];
           [self setQueryStartTimeTo:date];
            break;
        case 2:
            [self setQueryStartTimeTo:[self.Utils getNextWeekend]];
            break;
        default:
            [self setQueryStartTimeTo:date];
            break;
    }
}

/** **/
-(void)setQueryStartTimeTo:(NSDate *)date
{
    [self setQueryTime:[self.Utils formatDate:date pattern:@"yyyyMMddHHmmss" ]];
    NSLog(@"%@",   self.queryTime);
}

/** **/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

/** **/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.filters count];
}

/** **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dynamic fix identifier for fix table
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];
    
    if( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];
        
        NSDictionary *model = (NSDictionary *)[self.filters objectAtIndex:indexPath.row];
        UIView *selectedBackgroundViewForCell = [UIView new];
        [selectedBackgroundViewForCell setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.05]];
        cell.selectedBackgroundView = selectedBackgroundViewForCell;
        cell.userInteractionEnabled = YES;
        
        NSString *label = [model valueForKey:@"label"] ? [model valueForKey:@"label"] : @"";
        [cell.textLabel setText:label];
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-light" size:18]];
        
        EVEMapSwitch *switchView = [[EVEMapSwitch alloc] initWithFrame:CGRectZero];
        [switchView setTag:[indexPath row]+1];
        switchView.model = model;
        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchView;
        
    }
    
    return cell;
}

/** @TODO **/
-( void ) switchChanged:(id)sender
{
    EVEMapSwitch *togg = (EVEMapSwitch *)sender;
    NSDictionary *model = togg.model;
    int index = togg.tag-1;
    NSString *tags = [model valueForKey:@"tags"];
    

    NSLog(@"%@", tags);
    NSLog(@"%i", togg.tag);
    NSLog(@"%d", [sender isOn]);
    NSLog(@"%i", index);
    
    
    @try {
        if([sender isOn]) [(NSMutableDictionary *)[self.filters objectAtIndex:index] setValue:@YES forKey:@"enable"];
        else [(NSMutableDictionary *)[self.filters objectAtIndex:index] setValue:@NO forKey:@"enable"];
        
         NSLog(@"%@", [self.filters objectAtIndex:index] );
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    @finally {
        nil;
    }
}

/** **/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    EVEMapSwitch *cellSwitch = (EVEMapSwitch *)cell.accessoryView;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([cellSwitch isOn])
    {
        [cellSwitch setOn:NO animated:YES];
    }
    else
    {
        [cellSwitch setOn:YES animated:YES];
    }
    [self switchChanged:cellSwitch];
}

/** **/
-(void) viewWillAppear:(BOOL)animated
{
//    [self refresh];
}

/** **/
-( void ) viewDidAppear:(BOOL)animated
{
    
}



@end
