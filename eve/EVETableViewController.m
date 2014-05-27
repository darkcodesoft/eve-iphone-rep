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

@interface EVETableViewController ()
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
    [self initConfig];
    [self getCollection];
    
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
    
    if([CLLocationManager locationServicesEnabled])
    {
        [self.Utils locateUser];
        
        NSMutableDictionary *config =[[NSMutableDictionary alloc] init];
        [config setValue:[[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"City"] forKey:@"city"];
        [config setValue:[[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"State"] forKey:@"region"];
        [config setValue:[[self.Utils.Defaults objectForKey:@"userAddress"] valueForKey:@"Country"] forKey:@"country"];
        [config setValue:[self.Utils dateStringToUTC:[NSString stringWithFormat:@"%@", [NSDate date]]] forKey:@"startTime"];
        self.feed = [self.Utils getFeedWithConfig:config];
    }
    else self.feed = @"/api/trending/";
    
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 45)];
    self.header = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.titleView.bounds.size.width, 20)];
    self.header.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    self.header.textAlignment = NSTextAlignmentCenter;
    self.subHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.titleView.bounds.size.width, 20)];
    self.subHeader.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    self.subHeader.textAlignment = self.header.textAlignment = NSTextAlignmentCenter;
    self.subHeader.alpha = .7;
    self.header.textColor = self.subHeader.textColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    self.titleView.userInteractionEnabled = YES;
    [self.titleView addSubview:self.header];
    [self.titleView addSubview:self.subHeader];
    
    self.navigationItem.titleView = self.titleView;

    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(initSearch)];
    self.navigationItem.leftBarButtonItem = searchButton;
   
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(initPostController)];
    self.navigationItem.rightBarButtonItem = addButton;
    
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
-( void ) initPostController
{
    [self.Utils initPostController:self];
}

/** **/
-( void ) drawMessageView
{
    self.messageView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
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

/** **/
-( void ) presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated
{

}

/**
 * @desc set collection for feed
 * @method getFeed:page:
 **/
-( void ) getFeed:( NSString *)feedPath page:(int) pageParam
{
    self.results = [self.Utils getCollectionforFeed:[[NSString alloc] initWithFormat:@"%@%i", feedPath, pageParam]];
    //NSLog(@"%lu", (unsigned long)[self.results count]);
    
    if( [self.results count] > 0 )
    {
        NSArray *copy = [NSArray arrayWithArray:self.collection];
        self.collection = [copy arrayByAddingObjectsFromArray:self.results];
        self.fetching = NO;
    }
    
    [self hideMessageView];
}

/**
 * @desc refresh feed
 **/
-( void ) getCollection
{
    if( self.fetching ) return;
    self.fetching = YES;
    
    if( [self.Utils eveIsOnline] ){
    
    int64_t delayInSeconds = 1.0f;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self getFeed:self.feed page:self.set];
        [self.refreshControl endRefreshing];
        [self.spinner stopAnimating];
        [self.tableView reloadData];
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
    });
    }
    else
    {
        [self.Utils netWorkErrorHandler];
        self.fetching = NO;
    }
}

/** **/
-( void ) refreshCollection
{
    if( self.fetching ) return;
    
    if( [self.Utils eveIsOnline] )
    {
        self.collection =[[NSArray alloc] init];
        self.set = 1;
        [self getCollection];
        
        int64_t delayInSeconds = 2.1f;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.tableView setContentOffset:CGPointMake(0, -64) animated:NO];
        });
    }
    else
    {
        [self.Utils netWorkErrorHandler];
    }
}

/** **/
-( void ) updateCollection:(NSDictionary *) config
{
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.frame = CGRectMake(0, 0, 320, 60);
    self.spinner.clipsToBounds = YES;
    [self.spinner startAnimating];
    self.navigationItem.titleView = self.spinner;
    self.searchKeyWord = [config valueForKey:@"name"];
    self.searchTags = [config valueForKey:@"tags"];
    self.feed = [self.Utils getFeedWithConfig: config];
    [self refreshCollection];
    
    NSLog( @"%@", self.feed );
}

/**
 * @desc get next set
 **/
-( void ) getNextCollectionSet
{
    self.set++;
    [self.spinner startAnimating];
    [self.tableView zoomToRect:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 60.0) animated:YES];
    [self getCollection];
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
    [cell.descLabel setText:[model objectForKey:@"description"]];
    [cell.tagsLabel setText:[NSString stringWithFormat:@"%@", tagString]];
    [cell.timeLabel setText:[timeString uppercaseString]];
    [cell.distanceLabel setText:[[[model objectForKey:@"price"] intValue] == 0 ? @"Free" : [model objectForKey:@"admission"] uppercaseString]];
    
    return cell;
}

/**
 * @desc Get Directions
 **/
-( void )findDistanceFrom:(MKMapItem *)source to:(MKMapItem *)destination forLabel:( UILabel *) label
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = source;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    request.destination = destination;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = [response.routes firstObject];
        [label setText: [NSString stringWithFormat:@"%0.1f Miles", ceil(route.distance/1609.344)]];
        
    }];
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
        // NSLog(@"botttom");
        if( [self.results count] == 100 )
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
    // Navigation logic may go here, for example:
    // Create the next view controller.
    
    EVEDetailViewController *itemViewController = [[EVEDetailViewController alloc] init];
    [itemViewController applyConfig:attributes];
    itemViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:itemViewController animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



#pragma mark - Table view delegate


@end
