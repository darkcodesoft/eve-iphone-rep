//
//  EVEItemViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/17/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEItemViewController.h"
#import "EVEDescriptionViewController.h"
#import "EVEAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "EVEUtils.h"

@interface EVEItemViewController () <MKMapViewDelegate>
@property (nonatomic, strong) EVEAnnotation *annotation;
@property (nonatomic, strong) EVEUtils *Utils;
@property (nonatomic, weak) CLLocationManager *locationManager;
@property (nonatomic, weak) IBOutlet MKMapView *MapView;
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
@property (nonatomic, weak) IBOutlet UIButton *goButton;
@property (nonatomic, weak) IBOutlet UIView *wrapper;
@property (nonatomic, weak) IBOutlet UIView *wrapperHead;
@property (nonatomic) BOOL isMapExpanded;

@end

@implementation EVEItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**
 *
 **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initConfig];
    [self initListeners];
    [self drawMap];
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
    
}

/**
 *
 **/
-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    
    self.isMapExpanded = NO;
    
    self.startTtime = [self.Utils parseUTCDate:self.startTtime pattern:@"EEEE MMM d @ h:mm a"];
    self.endTime = [self.Utils parseUTCDate:self.endTime];
    
    self.nameLabel.text = self.name;
    self.descLabel.text = self.description;
    self.streetLabel.text = self.street;
    self.cityLabel.text = [self.city uppercaseString];
    self.regionLabel.text = [self.region uppercaseString];
    self.countryLabel.text = [self.countryName uppercaseString];
    self.admissionLabel.text = self.admission;
    self.currencyLabel.text = self.currency;
    self.userNameLabel.text = self.userName;
    self.dateLabel.text = self.startTtime;
    self.tagsLabel.text = [[[NSArray arrayWithArray:self.tags] componentsJoinedByString:@", "] capitalizedString];
    
    // navbar   
    UIBarButtonItem *saveBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self.Utils action:@selector(initSearch)];
    self.navigationItem.rightBarButtonItem = saveBarButton;
}

/** **/
-( void ) initListeners
{
    UITapGestureRecognizer *descTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTextView:)];
    [self.descLabel addGestureRecognizer:descTap];
    
    UITapGestureRecognizer *nameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTextView:)];
    [self.nameLabel addGestureRecognizer:nameTap];
    
    UITapGestureRecognizer *transTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(initTransaction)];
    [self.admissionLabel addGestureRecognizer:transTap];
}

/** **/
-( void ) selectLabel:(UILabel *)sender
{
    sender.textColor = [UIColor redColor];
}

/** **/
-( void ) deselectLabel:( UILabel *)label
{
    label.textColor = [UIColor darkGrayColor];
}

/** **/
-( void ) showTextView:(UILabel *)sender
{
    NSLog(@"Extended description.");
    EVEDescriptionViewController *descriptionViewController = [[EVEDescriptionViewController alloc] init];
    // Pass the selected object to the new view controller.
    descriptionViewController.headline = self.name;
    descriptionViewController.subHeadline = self.startTtime;
    descriptionViewController.body = self.description;
    descriptionViewController.note = self.address;
    // Push the view controller.
    [self.navigationController pushViewController:descriptionViewController animated:YES];
}

/** **/
-( void ) initTransaction
{
    NSLog(@"Transaction initialized.");
}

/**
 *
 **/
-( void ) drawMap
{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000);
    [self.MapView setRegion:region animated:YES];
    self.MapView.showsUserLocation = YES;
    [self.MapView setDelegate:self];
    
    self.annotation =[[EVEAnnotation alloc] initWithTitle:self.startTtime subTitle:self.address location:location];
    [self.MapView addAnnotation: self.annotation];
}

/**
 *
 **/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *
 **/
-(void)viewWillAppear:(BOOL)animated
{
    
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
        if( self.isMapExpanded == NO )
        {
            CLLocationCoordinate2D destinationCoord = CLLocationCoordinate2DMake( self.latitude, self.longitude);
            MKPlacemark *destinationMark = [[MKPlacemark alloc] initWithCoordinate:destinationCoord addressDictionary:nil];
            MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationMark];
            
            [self findDirectionsFrom:destinationItem to:[MKMapItem mapItemForCurrentLocation]];
            
            [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
                //Animations
                [self.MapView setFrame:CGRectMake(0, 0, 320, 500)];
                [self.wrapperHead setFrame:CGRectMake(0, 390, self.wrapperHead.bounds.size.width, self.wrapperHead.bounds.size.height)];
                [self.wrapper setFrame:CGRectMake(0, 400, self.wrapper.bounds.size.width, self.wrapper.bounds.size.height)];
                
            } completion:^(BOOL finished) {
                //Completion Block
                self.isMapExpanded = YES;
                
            }];
        }
        else
        {
            [self.MapView removeOverlays:[mapView overlays]];
            [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
                //Animations
                [self.MapView setFrame:CGRectMake(0, 0, 320, 280)];
                [self.wrapperHead setFrame:CGRectMake(0, 240, self.wrapperHead.bounds.size.width, self.wrapperHead.bounds.size.height)];
                [self.wrapper setFrame:CGRectMake(0, 280, self.wrapper.bounds.size.width, self.wrapper.bounds.size.height)];
                
            } completion:^(BOOL finished) {
                //Completion Block
                self.isMapExpanded = NO;
            }];
        }

        [self.MapView deselectAnnotation:annotationView.annotation animated:YES];
    }
}


/** **/
- (void)findDirectionsFrom:(MKMapItem *)source
                        to:(MKMapItem *)destination
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
    [directionss calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
        self.title = [NSString stringWithFormat:@"%i Mins", (int)ceil(response.expectedTravelTime/60.0)];
        
    }];
}

/** **/
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    MKPolylineRenderer *polylineRender = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    polylineRender.lineWidth = 5.0f;
    polylineRender.strokeColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:.75];
    return polylineRender;
}

@end
