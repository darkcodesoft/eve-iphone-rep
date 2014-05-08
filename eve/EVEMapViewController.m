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
#import "EVEItemViewController.h"
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
@property (nonatomic, strong) NSArray *menu;
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
@property (nonatomic) BOOL filterOpen;
@property (nonatomic) int set;

-( IBAction )dateControlSelected:(id)sender;

@end


@implementation EVEMapViewController

/** **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.Utils = [EVEUtils new];
    [self initLocationManager];
    [self startTrackingUser];
    [self initConfig];
    [self initTitleView];
    [self setAnnotations];
    [self.MapView addAnnotations:self.annotations];
    [self drawFilter];
    
    // init listeners
    [self initListeners];
}

/** **/
-( void ) initConfig
{
    // get feed
    self.set = 1;
    
    NSMutableDictionary *config =[[NSMutableDictionary alloc] init];
    [config setValue:[[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"State"] forKey:@"region"];
    [config setValue:[[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"Country"] forKey:@"country"];
    [config setValue:[self.Utils dateStringToUTC:[NSString stringWithFormat:@"%@", [NSDate date]]] forKey:@"startTime"];
    self.feed = [self.Utils getFeedWithConfig:config];
    
    [self getFeed:self.feed page:self.set];
    
    // add button
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(initPostController)];
    self.navigationItem.rightBarButtonItem = addButton;

    // filterbutton
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleFilter)];
    self.navigationItem.leftBarButtonItem = filterButton;
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
}

/** **/
-( void ) drawFilter
{
    self.filterOpen = NO;
    self.filterView.clipsToBounds = YES;
    [self.filterView setHidden:YES];
    
    self.dateControl.tintColor = [self.Utils.theme valueForKey:@"themeColor"];
    self.dateControlScroll.contentSize = CGSizeMake( self.dateControl.bounds.size.width + 31, 40 );
    
    CAGradientLayer *alphaGradientLayer = [CAGradientLayer layer];
    NSArray *colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0 alpha:0] CGColor],
                       (id)[[UIColor colorWithWhite:0 alpha:1] CGColor],
                       nil];
    
    [alphaGradientLayer setColors:colors];
    // Start the gradient at the bottom and go almost half way up.
    [alphaGradientLayer setStartPoint:CGPointMake(0, 1)];
    [alphaGradientLayer setEndPoint:CGPointMake(0, 0.75)];
    [alphaGradientLayer setFrame:[self.menuList frame]];
    [[self.menuListView layer] setMask:alphaGradientLayer];
    
    NSArray *menuArray = [NSArray arrayWithObjects:
                @{@"label" : @"Fashion", @"id": @"fashion", @"tags": @"fashion"},
                @{@"label" : @"Arts", @"id": @"arts", @"tags": @"arts, museum, performance"},
                @{@"label" : @"Party", @"id": @"party", @"tags": @"party, pool"},
                @{@"label" : @"Class", @"id": @"class", @"tags": @"class"},
                @{@"label" : @"Community", @"id": @"commnunity", @"tags" : @"park, block, neighborhood, community"},
                @{@"label" : @"Nighlife", @"id": @"nightlife", @"tags": @"club"},
                @{@"label" : @"Dance", @"id": @"dance", @"tags": @"dance"},
                @{@"label" : @"Concert", @"id": @"concert", @"tags": @"music, performance"},
                nil];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    self.menu = [menuArray sortedArrayUsingDescriptors:sortDescriptors];
}

/** **/
-( void ) toggleFilter
{
    if( self.filterOpen ) [self hideFilter];
    else [self showFilter];
}

/** **/
-( void ) hideFilter
{
    self.filterOpen = NO;
    CGRect frame = [self.filterView frame];
    
    // hide annos
    for( EVEAnnotation *anno in [self.MapView annotations])
    {
        [[self.MapView viewForAnnotation:anno] setAlpha:0];
        [[self.MapView viewForAnnotation:anno] setHidden:NO];
    }
    
    frame.origin.y = - self.filterView.frame.size.height + filterViewHeight;
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.filterView setFrame:frame];
    } completion:^(BOOL finished) {
        //Completion Block
        [self.filterView setHidden:YES];
        
        for( EVEAnnotation *anno in [self.MapView annotations])
        {
            [UIView animateWithDuration:.3 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
                //Animations
                [self.filterView setFrame:frame];
                [[self.MapView viewForAnnotation:anno] setAlpha:1];
            } completion:^(BOOL finished) {
                //Completion Block
            }];
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
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.filterView setFrame:frame];
    } completion:^(BOOL finished) {
        //Completion Block
        [self.filterView setHidden:NO];
        for( EVEAnnotation *anno in [self.MapView annotations])
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
    }];
}

/** **/
-( void ) setAnnotations
{
    for ( int i = 0; i < self.collection.count; i++ )
    {
        id object = [self.collection objectAtIndex:i];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[object valueForKey:@"latitude"] floatValue], [[object valueForKey:@"longitude"] floatValue]);
        EVEAnnotation *annotation =[[EVEAnnotation alloc] initWithTitle:[object valueForKey:@"name"] subTitle:[self.Utils parseUTCDate:[object valueForKey:@"startTime"] pattern:@"EEEE MMM d @ h:mm a"] location:location];
        annotation.config = object;
        [self.MapView addAnnotation: annotation];
    }
}

/**
 * @desc set collection for feed
 * @method getFeed:page:
 **/
-( void ) getFeed:( NSString *)feedPath page:(int) pageParam
{
    self.collection = [self.Utils getCollectionforFeed:[[NSString alloc] initWithFormat:@"%@%i", feedPath, pageParam]];
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
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location2d, 5000, 5000);
    
    [self.MapView setRegion:region animated:YES];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error) {
            NSLog(@"Error %@", error.description);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            [self.Utils.Defaults setObject:placemark.addressDictionary forKey:@"userAddress"];
            
            [self.locationManager stopUpdatingLocation];
            
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


/** **/
-( void ) mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{

}

/** **/
-( void ) mapViewDidFinishLoadingMap:(MKMapView *)mapView{

}

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
        //NSDictionary *attributes = (NSDictionary *)[self.collection objectAtIndex:indexPath.row];
        // Navigation logic may go here, for example:
        // Create the next view controller.
        EVEAnnotation *viewAnno = view.annotation;
        
        EVEItemViewController *itemViewController = [[EVEItemViewController alloc] init];
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
        self.subHeader.text = [NSString stringWithFormat:@"%@, %@", [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"City"], [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"State"]];
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
    
    MKDirections *directionss = [[MKDirections alloc] initWithRequest:request];
    [directionss calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = [response.routes firstObject];
        self.subHeader.text = [NSString stringWithFormat:@"%0.1f Miles Away", ceil(route.distance/1609.344)];
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
    //NSLog(@"%@",   date);
    //@todo
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
    return [self.menu count];
}

/** **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dynamic fix identifier for fix table
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];
    
    if( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];
        
        NSDictionary *model = (NSDictionary *)[self.menu objectAtIndex:indexPath.row];
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
    NSString *cat = [model valueForKey:@"id"];
    NSString *tags = [model valueForKey:@"tags"];
    
    NSLog(@"%@", cat);
    NSLog(@"%@", tags);
    
    for( EVEAnnotation *ann in [self.MapView annotations] )
    {
        if( [ann isKindOfClass:[EVEAnnotation class]] )
        {
            NSDictionary *config = ann.config;
            if( [[config objectForKey:@"tags"] indexOfObject:[model valueForKey:@"tags"]] )
            {
                // do your thing with matching objects here
                // NSLog(@"%@", config);
            }
        }
    }
    
    // NSLog(@"%@", model);
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
    [self drawMap];
    [self startTrackingUser];
}

/** **/
-( void ) viewDidAppear:(BOOL)animated
{
    
}



@end
