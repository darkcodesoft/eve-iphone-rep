//
//  EVETableViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/4/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "EVETableViewController.h"
#import "EVEItemViewController.h"
#import "EVEDetailViewController.h"
#import "EVEFilterViewController.h"
#import "EVECell.h"
#import "EVEUtils.h"

static NSString *CellID = @"list-table-cell";

@interface EVETableViewController () <CLLocationManagerDelegate>
@property ( nonatomic, strong ) UIView *titleView;
@property ( nonatomic, strong ) EVEUtils *Utils;
@property ( nonatomic, strong ) NSString *feed;
@property ( nonatomic, strong ) UILabel *header;
@property ( nonatomic, strong ) UILabel *subHeader;
@property ( nonatomic, strong ) NSArray *results;
@property ( nonatomic ) int set;
@property ( nonatomic, strong ) UIActivityIndicatorView *spinner;
@property ( nonatomic, strong ) UIView *BottomRefreshControl;
@property ( nonatomic, strong ) UIScrollView *messageView;
@property ( nonatomic, strong ) UILabel *messageSubject;
@property ( nonatomic, strong ) UILabel *messageBody;
@property ( nonatomic, strong ) NSString *searchKeyWord;
@property ( nonatomic, strong ) NSString *searchTags;
@property ( nonatomic, strong ) CLGeocoder *geocoder;
@property ( nonatomic, strong ) CLLocationManager *locationManager;
@property ( nonatomic, strong ) UIView *titleLabel;
@property (nonatomic) int limit;

@property ( nonatomic ) BOOL fetching;
@end

@implementation EVETableViewController

/** 
 * @initializer
 **/
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self )
    {
        [self.tableView registerNib:[UINib nibWithNibName:@"EVECell"bundle:nil] forCellReuseIdentifier:CellID];
        [self setRefreshControl];
    }
    return self;
}

/** **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    self.Utils = [EVEUtils new];
    [self drawMessageView];
    [self setTitleView];
    [self initConfig];
    [self initLocationManager];
    [self startTrackingUser];
    
    // init listeners
    [self initListeners];
}

/**
 * @desc
 * @method initConfig
 **/
-( void ) initConfig
{
    self.set = 1;
    self.fetching = NO;
    self.limit = 50;
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(initSearch)];
    self.navigationItem.rightBarButtonItem = searchButton;
    
    // geocoder
    self.geocoder = [[CLGeocoder alloc] init];
    
    // draw message view
    [self showMessageView];
}

/** **/
-( void ) initListeners
{
    UITapGestureRecognizer *titleViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleViewInitSearch)];
    [self.titleView addGestureRecognizer:titleViewTap];
}


/** **/
-( void ) setTitleView
{
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 45)];
    self.header = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.titleView.bounds.size.width, 20)];
    self.header.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    self.header.textAlignment = NSTextAlignmentCenter;
    self.subHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.titleView.bounds.size.width, 20)];
    self.subHeader.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    self.subHeader.textAlignment = self.header.textAlignment = NSTextAlignmentCenter;
    self.subHeader.alpha = .7;
    //self.header.textColor = self.subHeader.textColor = [self.Utils.theme valueForKey:@"themeColor"];
    self.header.textColor = self.subHeader.textColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    self.titleView.userInteractionEnabled = YES;
    [self.titleView addSubview:self.header];
    [self.titleView addSubview:self.subHeader];
    
    self.titleLabel = self.titleView;
    self.navigationItem.titleView = self.titleView;
}

/** **/
-( void ) drawMessageView
{
    self.messageView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.messageView.backgroundColor = [UIColor whiteColor];
    self.messageView.contentSize = CGSizeMake( self.view.bounds.size.width, self.view.bounds.size.height + 1 );
    [self.messageView setShowsVerticalScrollIndicator:NO];
    
    self.messageSubject = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, self.view.bounds.size.width - 60, 20)];
    self.messageSubject.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    
    self.messageBody = [[UILabel alloc] initWithFrame:CGRectMake(35, 200, self.view.bounds.size.width - 70, 80)];
    self.messageBody.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.messageBody.numberOfLines = 100;
    
    self.messageSubject.alpha = self.messageBody.alpha = 0;
    
    self.messageSubject.textAlignment = self.messageBody.textAlignment = NSTextAlignmentCenter;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.frame = CGRectMake(0, self.view.bounds.size.height/4 + 10, self.view.bounds.size.width, 100);
    self.spinner.tintColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    self.spinner.clipsToBounds = YES;
    [self.spinner startAnimating];
    self.navigationItem.titleView = self.spinner;
    
    [self.messageView addSubview:self.spinner];
    [self.messageView addSubview:self.messageSubject];
    [self.messageView addSubview:self.messageBody];
    [self.view insertSubview:self.messageView atIndex:2];
}

/** **/
-( void ) showMessageView
{
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.scrollEnabled = NO;
    self.messageView.alpha = 1;
    [UIView animateWithDuration:1.8 delay:0.0 usingSpringWithDamping:.7 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        self.messageSubject.alpha = 1;
        [self.messageSubject setFrame:CGRectMake(30, 150, self.view.bounds.size.width - 60, 20)];
    } completion:^(BOOL finished) {
        //Completion Block
    }];
    [UIView animateWithDuration:1.5 delay:0.1 usingSpringWithDamping:.7 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        self.messageBody.alpha = 1;
        [self.messageBody setFrame:CGRectMake(35, 150, self.view.bounds.size.width - 70, 80)];
    } completion:^(BOOL finished) {
        //Completion Block
    }];
}

/** **/
-( void ) hideMessageView
{
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.scrollEnabled = YES;
    [UIView animateWithDuration:.5 delay:0.0 usingSpringWithDamping:.7 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        self.messageView.alpha = 0;
    } completion:^(BOOL finished) {
        //Completion Block
        self.messageSubject.alpha = self.messageBody.alpha = 0;
        [self.messageBody setFrame:CGRectMake(35, 200, self.view.bounds.size.width - 70, 80)];
        [self.messageSubject setFrame:CGRectMake(30, 100, self.view.bounds.size.width - 60, 20)];
    }];
}

/** **/
-( void ) initSearch
{
    EVEFilterViewController *searchViewController = [[EVEFilterViewController alloc] init];
    searchViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    searchViewController.delegate = self;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    [self presentViewController:navController animated:YES completion:^(void){
    
    }];
}

/** **/
-( void ) titleViewInitSearch
{
    [self.titleView setAlpha:0.1];
    [UIView animateWithDuration:1.5 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.titleView setAlpha:1.0];
    } completion:^(BOOL finished) {
        //Completion Block
    }];
    [self initSearch];
}


/**
 * @desc refresh feed
 **/
-( void ) getCollection:(bool) reset
{
    if( self.fetching ) return;
    
    self.fetching = YES;
    
    int64_t delayInSeconds = 1.0f;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        @try {
            
            self.results = [self.Utils getCollectionforFeed:[[NSString alloc] initWithFormat:@"%@", self.feed]];
            
            if( [self.results count] > 0 )
            {
                if( reset ) self.collection =[[NSArray alloc] init];
                
                NSArray *copy = [NSArray arrayWithArray:self.collection];
                self.collection = [copy arrayByAddingObjectsFromArray:self.results];
                
                [self.refreshControl endRefreshing];
                [self.spinner stopAnimating];
                
                [self.tableView reloadData];
                
                if( reset ) [self.tableView setContentOffset:CGPointMake(0, -64) animated:YES];
                
                self.navigationItem.titleView = self.titleView;
                
                NSDictionary *userLocation = [self.Utils.Defaults valueForKey:@"userAddress"];
                if( self.queryCity ) userLocation = self.queryCity;
                
                NSString *header = @"";
                if( [[userLocation valueForKey:@"City"] length] > 0 ) header = [userLocation valueForKey:@"City"];
                if( [self.queryKeyword length] > 0 ) header = self.queryKeyword;
                if( [[userLocation valueForKey:@"City"] length] > 0 && [self.queryKeyword length] > 0) header = [NSString stringWithFormat:@"%@, %@", [userLocation valueForKey:@"City"], self.queryKeyword];
                self.header.text = header;
                
                NSString *subheader = @"";
                if( [[userLocation valueForKey:@"State"] length] > 0 ) subheader = [userLocation valueForKey:@"State"];
                if( [[userLocation valueForKey:@"Country"] length] > 0 ) subheader = [userLocation valueForKey:@"Country"];
                if( [[userLocation valueForKey:@"State"] length] > 0 && [[userLocation valueForKey:@"Country"] length] > 0) subheader = [NSString stringWithFormat:@"%@, %@", [userLocation valueForKey:@"State"], [userLocation valueForKey:@"Country"]];
                
                self.subHeader.text = subheader;
                [self.tableView setTableFooterView:nil];
                self.view.backgroundColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
            }
            else
            {
                [EVEUtils alert:@"No match found." message:nil delegate:self];
                self.navigationItem.titleView = self.titleLabel;
            }
            
        }
        @catch (NSException *exception) {
            [self.Utils netWorkErrorHandler];
            [self setTitleView];
        }
        @finally {
            [self hideMessageView];
            self.fetching = NO;
        }
    });
}

/** **/
-( void ) refreshCollection
{
    if( self.fetching ) return;
    
    self.feed = [NSString stringWithFormat:@"/api/q?lat=%@&long=%@&time=%@&limit=%i&keyword=%@",
                 [self.queryCity valueForKey:@"lat"],
                 [self.queryCity valueForKey:@"long"],
                 [self.Utils formatDate:[NSDate date] pattern:@"yyyyMMddHHmmss" ],
                 self.limit,
                 self.queryKeyword ? [self.queryKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  : @""];
    
    [self getCollection:YES];
}

/** **/
-( void ) updateCollection
{
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.frame = CGRectMake(0, 0, 60, 60);
    self.spinner.clipsToBounds = YES;
    [self.spinner startAnimating];
    self.navigationItem.titleView = self.spinner;
    
    self.feed = [NSString stringWithFormat:@"/api/q?lat=%@&long=%@&time=%@&limit=%i&keyword=%@",
                 [self.queryCity valueForKey:@"lat"],
                 [self.queryCity valueForKey:@"long"],
                 self.queryTimestamp,
                 self.limit,
                 self.queryKeyword ? [self.queryKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  : @""];

    [self getCollection:YES];
}

/**
 * @desc get next set
 **/
-( void ) getNextCollectionSet
{
    [self.spinner startAnimating];
    [self.tableView zoomToRect:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 60.0) animated:YES];
    
    self.feed = [NSString stringWithFormat:@"/api/q?lat=%@&long=%@&time=%@&limit=%i&keyword=%@",
                 [self.queryCity valueForKey:@"lat"],
                 [self.queryCity valueForKey:@"long"],
                 [[self.collection lastObject] valueForKey:@"begin"],
                 self.limit,
                 self.queryKeyword ? [self.queryKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  : @""];
    
    [self getCollection:NO];
}

/** **/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
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
    return self.collection.count;
}


/** 
 * @desc setup table view cell
 **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EVECell *cell = (EVECell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    NSDictionary *model = (NSDictionary *)[self.collection objectAtIndex:indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIView *selectedBackgroundViewForCell = [UIView new];
    [selectedBackgroundViewForCell setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.05]];
    cell.selectedBackgroundView = selectedBackgroundViewForCell;
    cell.userInteractionEnabled = YES;
    
    NSString *tagString = [NSString stringWithString:[[[NSArray arrayWithArray:[model objectForKey:@"tags"]] componentsJoinedByString:@", "] uppercaseString]];
    NSString *timeString = [self.Utils parseUTCDate:[model objectForKey:@"startTime"] pattern:@"EEEE MMM d @ h:mm a"];
    cell.latitude = [[model objectForKey:@"latitude"] floatValue];
    cell.longitude = [[model objectForKey:@"longitude"] floatValue];
    
    [cell.nameLabel setText:[[model objectForKey:@"name"] uppercaseString]];
    [cell.descLabel setText:[model objectForKey:@"short_description"]];
    [cell.tagsLabel setText:[NSString stringWithFormat:@"%@", tagString]];
    [cell.timeLabel setText:[timeString uppercaseString]];
    [cell.distanceLabel setText:[[[model objectForKey:@"price"] intValue] == 0 ? @"Free" : [model objectForKey:@"admission"] uppercaseString]];
    
    return cell;
}

/**
 * @desc set tableView height value
 **/
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0;
}

/**
 * @desc
 * @method setRefreshControl
 **/
-( void ) setRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl = self.refreshControl;
  
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector( refreshCollection ) forControlEvents:UIControlEventValueChanged];

}

/** **/
-( void ) drawBottomRefreshControl
{
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.spinner stopAnimating];
    self.spinner.hidesWhenStopped = NO;
    self.spinner.frame = CGRectMake(0, 0, 320, 60);
    self.spinner.clipsToBounds = YES;
    [self.spinner stopAnimating];
}

/** **/
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height && self.fetching == NO) {
        // we are at the end
        if( [self.results count] == 50 )
        {
            [self drawBottomRefreshControl];
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.bounds.origin.y + 60) animated:YES];
            [self.tableView setTableFooterView:self.spinner];
            [self getNextCollectionSet];
        }
        else
        {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 60)];
            footer.backgroundColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, self.tableView.bounds.size.width - 30, 30)];
            label.text = @"End of list.";
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            
            [footer addSubview:label];
            [self.tableView setTableFooterView:footer];
        }
    }
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *attributes = (NSDictionary *)[self.collection objectAtIndex:indexPath.row];
    EVEDetailViewController *itemViewController = [[EVEDetailViewController alloc] init];
    [itemViewController applyConfig:attributes];
    itemViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:itemViewController animated:YES];
}

// this delegate is called when the app successfully finds your current location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
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
            
            if( !self.queryCity )
            {
                self.queryCity = [NSMutableDictionary new];
                
                [self.queryCity setValue:lat forKey:@"lat"];
                [self.queryCity setValue:lon forKey:@"long"];
                [self.queryCity setValue:[placemark.addressDictionary valueForKey:@"City"] forKey:@"City"];
                [self.queryCity setValue:[placemark.addressDictionary  valueForKey:@"State"] forKey:@"State"];
                [self.queryCity setValue:[placemark.addressDictionary  valueForKey:@"Country"] forKey:@"Country"];
                [self.queryCity setValue:[NSString stringWithFormat:@"%@, %@, %@",
                                          [placemark.addressDictionary valueForKey:@"City"],
                                          [placemark.addressDictionary valueForKey:@"State"],
                                          [placemark.addressDictionary valueForKey:@"CountryCode"]
                                          ] forKey:@"label"];
                
                self.feed = [NSString stringWithFormat:@"/api/q?lat=%@&long=%@&time=%@&limit=%i", lat, lon, [self.Utils formatDate:[NSDate date] pattern:@"yyyyMMddHHmmss" ], self.limit];
            }
            
            [self getCollection:YES];
        }
    }];
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

#pragma mark - Table view delegate


@end
