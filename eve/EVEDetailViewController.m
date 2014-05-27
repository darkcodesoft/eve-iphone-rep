//
//  EVEDetailViewController.m
//  eve
//
//  Created by Teddy Moussignac on 5/18/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

static NSString *mapsButtonTitle = @"Open in Maps";
static NSString *calendarTitle = @"Add to Calendar";

#import "EVEDetailViewController.h"
#import "EVEDescriptionViewController.h"
#import "EVEWebViewController.h"
#import "EVEAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "EVEUtils.h"
#import <Social/Social.h>
#import <EventKit/EventKit.h>

@interface EVEDetailViewController () <MKMapViewDelegate, UIActionSheetDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) EVEAnnotation *annotation;
@property (nonatomic, strong) EVEUtils *Utils;
@property (nonatomic, weak) CLLocationManager *locationManager;
@property (nonatomic, weak) IBOutlet MKMapView *MapView;
@property (nonatomic, weak) IBOutlet UIView *MapViewWrap;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *descLabel;
@property (nonatomic, weak) IBOutlet UILabel *cityLabel;
@property (nonatomic, weak) IBOutlet UILabel *regionLabel;
@property (nonatomic, weak) IBOutlet UILabel *countryLabel;
@property (nonatomic, weak) IBOutlet UILabel *streetLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;
@property (nonatomic, weak) IBOutlet UILabel *admissionLabel;
@property (nonatomic, weak) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak) IBOutlet UILabel *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UILabel *ETALabel;

@property ( nonatomic, weak ) IBOutlet UIView *calendarBar;
@property ( nonatomic, weak ) IBOutlet UIView *addressBar;
@property ( nonatomic, weak ) IBOutlet UIView *descBox;

@property ( nonatomic, weak ) IBOutlet UIView *topWrapper;
@property ( nonatomic, weak ) IBOutlet UIView *bottomWrapper;
@property ( nonatomic, weak ) IBOutlet UIView *wrapper;
@property ( nonatomic, weak ) IBOutlet UIScrollView *scrollView;
@property ( nonatomic, weak ) IBOutlet UIButton *imapButton;
@property ( nonatomic, weak ) IBOutlet UIView *imapButtonWrap;
@property ( nonatomic, weak ) IBOutlet UIButton *ticketButton;

@property ( nonatomic ) MKRoute *route;
@property ( nonatomic, strong ) NSString *dateString;
@property ( nonatomic ) CGRect mapViewFrame;
@property (nonatomic) BOOL isMapExpanded;
@property (nonatomic) BOOL ETAViewOn;
@end

@implementation EVEDetailViewController

/** **/
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/** **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initConfig];
    [self initListeners];
    [self drawMap];
    [self updateScroll];
}

/** **/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** **/
-( void ) applyConfig:( NSDictionary *) config
{
    self.id = [config valueForKey:@"self.id"];
    self.userId = [config valueForKey:@"userId"];
    self.userName = [config valueForKey:@"userName"];
    self.name = [config valueForKey:@"name"];
    self.startTtime = [config valueForKey:@"startTime"];
    self.endTime = [config valueForKey:@"endTime"];
    self.url = [config valueForKey:@"url"];
    self.created = [[config valueForKey:@"created"] intValue];
    self.admission = [config valueForKey:@"admission"];
    self.currency = [config valueForKey:@"currency"];
    self.price = [[config valueForKey:@"price"] intValue];
    self.description = [config valueForKey:@"description"];
    self.tags = [config valueForKey:@"tags"];
    self.venue = [config valueForKey:@"venue"];
    self.street = [config valueForKey:@"street"];
    self.region = [config valueForKey:@"region"];
    self.city = [config valueForKey:@"city"];
    self.countryName = [config valueForKey:@"countryName"];
    self.address = [config valueForKey:@"address"];
    self.latitude = [[config valueForKey:@"latitude"] floatValue];
    self.longitude = [[config valueForKey:@"longitude"] floatValue];
    self.tags = [config objectForKey:@"tags"];
    self.ETAViewOn = YES;
    
    [self calculateDistanceAndETA];
}

/** **/
-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    
    self.isMapExpanded = NO;
    
    self.dateString = [self.Utils parseUTCDate:self.startTtime pattern:@"EEEE MMM d @ h:mm a"];
    
    self.nameLabel.text = self.name;
    self.descLabel.text = self.description;
    self.streetLabel.text = self.address;
    self.cityLabel.text = [self.city uppercaseString];
    self.regionLabel.text = [self.region uppercaseString];
    self.countryLabel.text = [self.countryName uppercaseString];
    self.admissionLabel.text = self.price == 0 ? @"Free" : self.admission;
    self.currencyLabel.text = self.currency;
    self.userNameLabel.text = self.userName;
    self.dateLabel.text = self.dateString;
    self.tagsLabel.text = [[[NSArray arrayWithArray:self.tags] componentsJoinedByString:@", "] capitalizedString];
    [self toggleETAadnDistanceLabels];
    
    // navbar
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(initShare)];
    self.navigationItem.rightBarButtonItem = shareBarButton;
//    
//    UIImage *image = [UIImage imageNamed:@"left"];
//    
//    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [backButton setFrame:CGRectMake(0, 0, 32, 32)];
//    [backButton setTintColor:[UIColor whiteColor]];
//    [backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
//    [backButton setBackgroundImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//    
//    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
//    //self.navigationItem.leftBarButtonItem = backButtonItem;
    
    // mapView
    self.mapViewFrame = self.MapViewWrap.frame;
    
    // ticketButton
    if( self.price == 0 ) [self.ticketButton setTitle:@"GET PASS" forState:UIControlStateNormal];
}

/** **/
-( void ) initListeners
{
    UITapGestureRecognizer *calendarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(initCalendar)];
    [self.calendarBar addGestureRecognizer:calendarTap];

    UITapGestureRecognizer *addressTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleETAadnDistanceLabels)];
    [self.addressBar addGestureRecognizer:addressTap];
    
    UITapGestureRecognizer *descTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(initDetailDescription)];
    [self.descBox addGestureRecognizer:descTap];
}

/** **/
-( void ) updateScroll
{
    float heights = 0;
    float padding = 63;
    float delta = self.bottomWrapper.frame.size.height + padding;
    CGRect frame = self.view.frame;
    NSArray *views = [NSArray arrayWithArray:[self.wrapper subviews]];
    
    frame.size.height = self.view.frame.size.height - padding;
    
    for( UIView *view in views )
    {
        heights += view.frame.size.height;
    }
    
    if( heights > frame.size.height ) frame.size.height = heights + delta;
    self.scrollView.contentSize = frame.size;
}

/** **/
-( void ) initDetailDescription
{
    EVEDescriptionViewController *descViewController = [[EVEDescriptionViewController alloc] init];
    descViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    descViewController.body = self.description;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:descViewController];
    [self presentViewController:navController animated:YES completion:^(void){
        
    }];
}

/** **/
-( IBAction)initTicketsView:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSString *title = button.titleLabel.text;
    
    [self initTicketsViewWithTitle:title];
}

/** **/
-( void ) initTicketsViewWithTitle:(NSString *)title
{
    EVEWebViewController *webview = [[EVEWebViewController alloc] init];
    webview.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    webview.title = title;
    webview.url = self.url;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:webview];
    [self presentViewController:navController animated:YES completion:^(void){
        
    }];
    
}

/** **/
-( void ) initCalendar
{
    NSString *imaps = calendarTitle;
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:imaps, nil];
    
    [actionSheet showInView:self.view];
}

/** **/
-( void ) initMaps
{
    NSString *imaps = mapsButtonTitle;
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                    initWithTitle:nil
                                    delegate:self
                                    cancelButtonTitle:cancelTitle
                                    destructiveButtonTitle:nil
                                    otherButtonTitles:imaps, nil];

    [actionSheet showInView:self.view];
}

/** **/
-( void ) saveToCalendar
{
    NSDate *start = [self.Utils utcToDate:self.startTtime];
    NSDate *end = [self.Utils utcToDate:self.endTime];
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    NSPredicate *predicateForEventsOnHolidayDate = [eventStore predicateForEventsWithStartDate:start endDate:end calendars:nil]; // nil will search through all calendars
    NSArray *eventsOnHolidayDate = [eventStore eventsMatchingPredicate:predicateForEventsOnHolidayDate];
    BOOL eventExists = NO;
    
    for (EKEvent *eventToCheck in eventsOnHolidayDate) {
        if ([eventToCheck.title isEqualToString:self.name]) {
            eventExists = YES;
        }
    }
    
    if( eventExists )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hmm... You like this one." message:@"This event is aleardy in your calendar." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        
        dispatch_after(1.0f, dispatch_get_main_queue(), ^(void){
            [alert show];
        });
    }
    else
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            // handle access here
            EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:start];
            EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
            
            event.title = self.name;
            event.notes = self.description;
            event.location = self.address;
            event.startDate = start;
            event.endDate = end;
            
            [event addAlarm:alarm];
            [event setCalendar:[eventStore defaultCalendarForNewEvents]];
            NSError *err;
            [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
        
            if( !err )
            {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                
                // Set the fire date/time
                [localNotification setFireDate:start];
                [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
                
                localNotification.applicationIconBadgeNumber=1;
                
                // Setup alert notification
                [localNotification setAlertAction:@"UPost Event Reminder"];
                [localNotification setAlertBody:self.name];
                
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                [localNotification setHasAction:YES];      
                UIApplication *app = [UIApplication sharedApplication];
                [app scheduleLocalNotification:localNotification];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"Event added to calendar." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                dispatch_after(1.0f, dispatch_get_main_queue(), ^(void){
                    [alert show];
                });
            }
        }];
    }
}

/** **/
-( void ) initShare
{
    NSString *status = [NSString stringWithFormat:@"%@, %@, %@, %@", self.name, self.startTtime, self.city, self.region];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[status] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

/** **/
-( void ) drawMap
{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 200, 200);
    [self.MapView setRegion:region animated:YES];
    self.MapView.showsUserLocation = YES;
    [self.MapView setDelegate:self];
    
    self.annotation =[[EVEAnnotation alloc] initWithTitle:self.startTtime subTitle:self.address location:location];
    [self.MapView addAnnotation: self.annotation];
    
    self.imapButtonWrap.layer.cornerRadius = 5;
    //self.imapButtonWrap.backgroundColor = [UIColor whiteColor];
    [self.imapButton addTarget:self action:@selector(initMaps) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *image = [UIImage imageNamed:@"852-map-selected"];
    
    [self.imapButton setBackgroundImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.imapButton setTintColor:[self.Utils.theme valueForKey:@"themeColor"]];
}

/** **/
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[EVEAnnotation class]]) // use whatever annotation class you used when creating the annotation
    {
        EVEAnnotation *myAnnotation = (EVEAnnotation *) annotation;
        myAnnotation.hasDirection = YES;
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotation"];
        annotationView.image = [UIImage imageNamed:@"pin-large"];
        
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

/** **/
-( void ) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"Direction Request will go here tonight!");
}

/** **/
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView
{
    if( [annotationView.annotation isKindOfClass:[EVEAnnotation class]] )
    {
        CGPoint rect = self.addressBar.frame.origin;
        CGRect frame = self.MapViewWrap.frame;
        
        rect.y = self.addressBar.frame.origin.y - self.addressBar.frame.size.height - 15;
        frame.size.height = self.view.frame.size.height - self.addressBar.frame.size.height - 64;
    
        if( self.isMapExpanded == NO && self.route) [self expandMap:rect endFrame:frame];
        else [self collapaseMap];
            
        [self.MapView deselectAnnotation:annotationView.annotation animated:YES];
    }
}

/** **/
-( void ) expandMap:(CGPoint)endPoint endFrame:(CGRect) endFrame
{
    if( !self.isMapExpanded )
    {
        self.isMapExpanded = YES;
        [self.scrollView setContentOffset:endPoint animated:YES];
        
        [self.MapView addOverlay:self.route.polyline level:MKOverlayLevelAboveRoads];
        [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self.MapViewWrap setFrame:endFrame];
            [self.imapButtonWrap setAlpha:1];
        } completion:^(BOOL finished) {
            //Completion Block
            MKMapRect zoomRect = MKMapRectNull;
            for( id <MKAnnotation> annotation in self.MapView.annotations )
            {
                MKMapPoint annotationPoint = MKMapPointForCoordinate( annotation.coordinate );
                MKMapRect pointRect = MKMapRectMake( annotationPoint.x, annotationPoint.y, 0, 0 );
                if( MKMapRectIsNull( zoomRect )) zoomRect = pointRect;
                else zoomRect = MKMapRectUnion( zoomRect, pointRect );
            }
            
            [self.MapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake( 40, 40, 40, 40 ) animated:YES];
        }];
    }

}

/** **/
-( void ) collapaseMap
{
    if( self.isMapExpanded )
    {
        self.isMapExpanded = NO;
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:bottomOffset animated:YES];
        
        [self.MapView removeOverlays:[self.MapView overlays]];
        [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self.MapViewWrap setFrame:self.mapViewFrame];
            [self.imapButtonWrap setAlpha:0];
        } completion:^(BOOL finished) {
            //Completion Block
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake(self.latitude, self.longitude);
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 200, 200);
            [self.MapView setRegion:region animated:YES];
        }];
    }
}

/** **/
-( void ) toggleETAadnDistanceLabels
{
    if( self.ETAViewOn )
    {
        self.ETAViewOn = NO;
        [self.ETALabel setAlpha:0.35];
        [self.distanceLabel setAlpha:0];
    }
    else
    {
        self.ETAViewOn = YES;
        [self.ETALabel setAlpha:0];
        [self.distanceLabel setAlpha:0.35];
    }
}

/** **/
-( void ) calculateDistanceAndETA
{
    CLLocationCoordinate2D destinationCoord = CLLocationCoordinate2DMake( self.latitude, self.longitude);
    MKPlacemark *destinationMark = [[MKPlacemark alloc] initWithCoordinate:destinationCoord addressDictionary:nil];
    MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationMark];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = destinationItem;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    request.destination = [MKMapItem mapItemForCurrentLocation];
    
    // calculate ETA
    MKDirections *directionss = [[MKDirections alloc] initWithRequest:request];
    [directionss calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
        
        int res = (int)ceil(response.expectedTravelTime/60.0);
        NSString *eta = @"UNAVAILABLE";
        
        if( res > 0 ) eta = [[EVEUtils parseTime:res] uppercaseString];
        
        [self.self.ETALabel setText:eta];
    }];
    
    // calculate
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = [response.routes firstObject];
        
        self.route = route;
        int res = (int)ceil(route.distance/1609.344);
        NSString *distance = @"UNAVAILABLE";
        if( res > 0 ) distance = [[NSString stringWithFormat:@"%i Miles", res] uppercaseString];
        [self.distanceLabel setText:distance];
    }];
}


/** **/
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if  ([buttonTitle isEqualToString:mapsButtonTitle])
    {
        NSMutableString *addressString = [NSMutableString stringWithFormat:@"http://maps.apple.com/?q=%@", self.address];
        NSURL *url = [NSURL URLWithString:[addressString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[UIApplication sharedApplication] openURL:url];
    }
    
    if( [buttonTitle isEqualToString:calendarTitle] ) [self saveToCalendar];
}

/** **/
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    MKPolylineRenderer *polylineRender = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    polylineRender.lineWidth = 5.0f;
    polylineRender.strokeColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:.75];
    return polylineRender;
}

/** **/
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if( self.isMapExpanded ) [self collapaseMap];
    else return;
}


/** **/
-( void )dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
