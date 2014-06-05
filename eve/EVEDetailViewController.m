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
#import "TPAppDelegate.h"
#import "EVEUserViewController.h"

@interface EVEDetailViewController () <MKMapViewDelegate, UIActionSheetDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) EVEAnnotation *annotation;
@property (nonatomic, strong) EVEUtils *Utils;
@property (nonatomic, weak) CLLocationManager *locationManager;
@property (nonatomic, weak) IBOutlet MKMapView *MapView;
@property (nonatomic, weak) IBOutlet UIView *MapViewWrap;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *descLabel;
@property (nonatomic, weak) IBOutlet UILabel *streetLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;
@property (nonatomic, weak) IBOutlet UILabel *admissionLabel;
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
    self.id = [config valueForKey:@"id"] ? [config valueForKey:@"id"] : [config valueForKey:@"_id"];
    self.userName = [config valueForKey:@"userName"];
    self.name = [config valueForKey:@"name"];
    self.startTtime = [config valueForKey:@"startTime"];
    self.endTime = [config valueForKey:@"endTime"];
    self.url = [config valueForKey:@"url"];
    self.admission = [config valueForKey:@"admission"];
    self.price = [[config valueForKey:@"price"] intValue];
    self.tags = [config valueForKey:@"tags"];
    self.address = [config valueForKey:@"address"];
    self.latitude = [[config valueForKey:@"latitude"] floatValue];
    self.longitude = [[config valueForKey:@"longitude"] floatValue];
    self.description = [config valueForKey:@"short_description"];
    
    // set tags
    @try {
        self.tags = [config objectForKey:@"tags"];
    }
    @catch (NSException *exception) {
        self.tags = [config valueForKey:@"tags"];
    }
    @finally {
        nil;
    }
    
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
    self.admissionLabel.text = self.price == 0 ? @"Free" : self.admission;
    self.userNameLabel.text = self.userName;
    self.dateLabel.text = self.dateString;
    // set tags
    @try {
        self.tagsLabel.text = [[self.tags componentsJoinedByString:@", "] capitalizedString];
    }
    @catch (NSException *exception) {
        self.tagsLabel.text = [[NSString stringWithFormat:@"%@", self.tags] capitalizedString ];
    }
    @finally {
        nil;
    }
    
    // navbar
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(initShare)];
    self.navigationItem.rightBarButtonItem = shareBarButton;
    
    // mapView
    self.mapViewFrame = self.MapViewWrap.frame;
    
    // ticketButton
    if( self.price == 0 ) [self.ticketButton setTitle:@"GET PASS FROM OUR PARTNERS" forState:UIControlStateNormal];
    else [self.ticketButton setTitle:@"GET TICKETS FROM OUR PARTNERS" forState:UIControlStateNormal];
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
    
    UITapGestureRecognizer *btnTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(initMaps)];
    [self.imapButtonWrap addGestureRecognizer:btnTap];
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
    
    NSString *feed = [[NSString alloc] initWithFormat:@"/api/item/%@", self.id];
    
    if( [self.Utils eveIsOnline] )
    {
        NSArray *match = [self.Utils getCollectionforFeed:feed];
        if( match )
        {
            NSDictionary *item = ( NSDictionary *) match[0];
            EVEDescriptionViewController *descViewController = [[EVEDescriptionViewController alloc] init];
            descViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            descViewController.html = [item valueForKey:@"html_description"];
            UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:descViewController];
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
    else
    {
        [self.Utils netWorkErrorHandler];
    }
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
    if( [self.Utils eveIsOnline] )
    {
        EVEWebViewController *webview = [[EVEWebViewController alloc] init];
        webview.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        webview.url = self.url;
        UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:webview];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else
    {
        [self.Utils netWorkErrorHandler];
    }
}

/** **/
-( void ) initCalendar
{
    [self.calendarBar setAlpha:0];
    [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.calendarBar setAlpha:1];
    } completion:nil];
    
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
-( IBAction)initMaps
{
    [self.imapButton setAlpha:0];
    [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.imapButton setAlpha:1];
    } completion:nil];
    
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
        [EVEUtils alert:@"Hmm... You like this one." message:@"This event is aleardy in your calendar." delegate:self];
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
                // save to core data
                TPAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                NSManagedObjectContext *context = [appDelegate managedObjectContext];
                NSManagedObject *eve = [NSEntityDescription insertNewObjectForEntityForName:@"Eve" inManagedObjectContext:context];
                
                NSNumber *price = [[NSNumber alloc] initWithInt:self.price];
                
                [eve setValue:self.id forKey:@"id"];
                [eve setValue:self.name forKey:@"name"];
                [eve setValue:self.startTtime forKey:@"startTime"];
                [eve setValue:self.endTime forKey:@"endTime"];
                [eve setValue:self.description forKey:@"short_description"];
                [eve setValue:[self.tags componentsJoinedByString:@", "] forKey:@"tags"];
                [eve setValue:price forKey:@"price"];
                [eve setValue:self.price == 0 ? @"Free" : self.admission forKey:@"admission"];
                [eve setValue:self.dateString forKey:@"dateString"];
                [eve setValue:self.address forKey:@"address"];
                [eve setValue:[NSString stringWithFormat:@"%f", self.latitude] forKey:@"latitude"];
                [eve setValue:[NSString stringWithFormat:@"%f", self.longitude] forKey:@"longitude"];
                [eve setValue:self.url forKey:@"url"];
                [eve setValue:self.userName forKey:@"userName"];
                // save model
                if (![context save:&error]) NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                
                // set notification
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
                
                [EVEUtils alert:@"Done!" message:@"Event added to calendar." delegate:self];
            }
        }];
    }
}

/** **/
-( void ) initShare
{
    NSString *status = [NSString stringWithFormat:@"%@, %@, %@", self.name, self.dateString, self.address];
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
    
    self.imapButtonWrap.layer.cornerRadius = 4;
    
    UIImage *image = [UIImage imageNamed:@"852-map-selected"];
    
    [self.imapButton setBackgroundImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.imapButton setTintColor:[UIColor whiteColor]];
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
    
        if( self.isMapExpanded == NO )
        {
            if( self.route ) [self expandMap:rect endFrame:frame];
            else [EVEUtils alert:@"Route unavailable." message:nil delegate:nil];
        }
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
-(void) touchesBegan:(NSSet*) touches withEvent:(UIEvent *) event {
    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    
    if([self.imapButtonWrap.layer.presentationLayer hitTest:point]) {
        
        //do something
        return;
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
    [self.addressBar setAlpha:0];
    [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.addressBar setAlpha:1];
    } completion:nil];
    
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
