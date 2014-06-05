//
//  EVEUserViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/24/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEUserViewController.h"
#import "EVEUtils.h"
#import "TPAppDelegate.h"
#import "EVECell.h"
#import "EVEDetailViewController.h"
#import <EventKit/EventKit.h>

static NSString *CellID = @"list-table-cell";

@interface EVEUserViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) EVEUtils *Utils;
@property ( nonatomic, strong ) UIView *titleView;
@property ( nonatomic, strong ) UILabel *header;
@property ( nonatomic, strong ) UILabel *subHeader;
@property (nonatomic, strong) UIRefreshControl *calendarListrefreshControl;
@property (nonatomic, strong) TPAppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) UITableView *TableView;
@property (nonatomic, strong) EKEventStore *eventStore;
@end

@implementation EVEUserViewController

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
    [self retrieveModels];
}

/** **/
-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    
    self.navigationItem.title = @"Calendar";
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:nil];
    self.navigationItem.rightBarButtonItem = filterButton;
    
    // title
    [self setTitleView];
    
    // context
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.context = [self.appDelegate managedObjectContext];
    
    // calendarList
    self.eventStore = [[EKEventStore alloc] init];
    self.calendarListrefreshControl = [[UIRefreshControl alloc] init];
    [self.calendarListrefreshControl addTarget:self action:@selector(calendarListRefresh) forControlEvents:UIControlEventValueChanged];
    [self.calendarList addSubview:self.calendarListrefreshControl];
    self.calendarListrefreshControl.tintColor = [self.Utils.theme objectForKey:@"themeColor"];
    self.TableView = self.calendarList;
}

/** **/
-( void ) setTitleView
{
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 45)];
    
    self.header = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.titleView.bounds.size.width, 20)];
    self.header.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    self.header.textAlignment = NSTextAlignmentCenter;
    [self.header setText:@"MY"];
    
    self.subHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, self.titleView.bounds.size.width, 20)];
    self.subHeader.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    self.subHeader.textAlignment = self.header.textAlignment = NSTextAlignmentCenter;
    self.header.alpha = .7;
    [self.subHeader setText:@"Calendar"];
    
    self.header.textColor = self.subHeader.textColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    
    self.titleView.userInteractionEnabled = YES;
    [self.titleView addSubview:self.header];
    [self.titleView addSubview:self.subHeader];
    
    //self.titleLabel = self.titleView;
    self.navigationItem.titleView = self.titleView;
}

/** **/
-( void ) removeCalendarItem:(NSIndexPath *)path
{
    NSManagedObject *model = [self.calendarItems objectAtIndex:path.row];
    NSArray *keys = [[[model entity] attributesByName] allKeys];
    NSDictionary *mod = [model dictionaryWithValuesForKeys:keys];
    
    [self.TableView beginUpdates];
    [self.TableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    [self retrieveModels];
    [(NSMutableArray *)self.calendarItems removeObjectAtIndex:path.row];
   
    [self.context deleteObject:model];
    if (![self.context save:nil]) NSLog(@"Whoops, couldn't delete." );
   
    NSDate *start = [self.Utils utcToDate:[mod valueForKey:@"startTime"]];
    NSDate *end = [self.Utils utcToDate:[mod valueForKey:@"endTime"]];
    
    NSPredicate *predicateForEventsOnHolidayDate = [self.eventStore predicateForEventsWithStartDate:start endDate:end calendars:nil]; // nil will search through all calendars
    NSArray *eventsOnHolidayDate = [self.eventStore eventsMatchingPredicate:predicateForEventsOnHolidayDate];
    
     [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
         for (EKEvent *event in eventsOnHolidayDate) {
             if ([event.title isEqualToString:[mod valueForKey:@"name"]]) {
                 NSError *xerror = nil;
                 [self.eventStore removeEvent:event span:EKSpanFutureEvents error:&xerror];
                 if( xerror ) NSLog(@"An error ooccured: %@", xerror);
             }
         }
     }];
    
    [self.TableView endUpdates];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [self removeCalendarItem:indexPath];
    }
}

/** **/
-( void ) initPostController
{
    [self.Utils initPostController:self];
}

/** **/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Action method executes when user touches the button
-(void) pickOne:(id)sender{
    //UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    //label.text = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
}

/** **/
-( void ) retrieveModels
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Eve" inManagedObjectContext:self.context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
    
    NSError *error;
    NSMutableArray *objects = [(NSMutableArray *)[self.context executeFetchRequest:request error:&error] mutableCopy];
    
    if ([objects count] == 0) NSLog(@"No matches");
    else self.calendarItems = objects;
}

/** **/
-( void )calendarListRefresh
{
    [self retrieveModels];
    
    dispatch_after(1.0f, dispatch_get_main_queue(), ^(void){
        [self.calendarListrefreshControl endRefreshing];
        [self.calendarList reloadData];
    });

}

/** **/
-( void ) viewDidAppear:(BOOL)animated
{
    [self calendarListRefresh];
}

/**
 * @desc setup table view cell
 **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
    [self.calendarList registerNib:[UINib nibWithNibName:@"EVECell"bundle:nil] forCellReuseIdentifier:CellID];
    // dynamic fix identifier for fix table
    EVECell *cell = (EVECell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    if( cell == nil ) cell = (EVECell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    NSDictionary *model = (NSDictionary *)[self.calendarItems objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIView *selectedBackgroundViewForCell = [UIView new];
    [selectedBackgroundViewForCell setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.05]];
    cell.selectedBackgroundView = selectedBackgroundViewForCell;
    cell.userInteractionEnabled = YES;
    
    [cell.nameLabel setText:[[model valueForKey:@"name"] uppercaseString]];
    [cell.descLabel setText:[model valueForKey:@"short_description"]];
    [cell.tagsLabel setText:[model valueForKey:@"tags"]];
    [cell.timeLabel setText:[[model valueForKey:@"dateString"] uppercaseString]];
    [cell.distanceLabel setText:[[model valueForKey:@"admission"] uppercaseString]];

    return cell;
}

/**
 * @desc set tableView height value
 **/
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0;
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
    return [self.calendarItems count];
}

/** **/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *model = (NSDictionary *)[self.calendarItems objectAtIndex:indexPath.row];
    
    EVEDetailViewController *itemViewController = [[EVEDetailViewController alloc] init];
    [itemViewController applyConfig:model];
    itemViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:itemViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/** **/
-( void ) fetchForItemWithId:(NSString *) id
{
    NSString *feed = [[NSString alloc] initWithFormat:@"/api/item/%@", id];
    NSArray *match = [self.Utils getCollectionforFeed:feed];
    
    if( match )
    {
        NSDictionary *item = ( NSDictionary *) match[0];
        
        EVEDetailViewController *itemViewController = [[EVEDetailViewController alloc] init];
        [itemViewController applyConfig:item];
        itemViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:itemViewController animated:YES];
    }
    else
    {
        [EVEUtils alert:@"This event was not found on the server." message:nil delegate:self];
    }
}

/** **/
-( void ) syncModel:(NSString *)id attributes:(NSDictionary *) attributes
{
    NSManagedObject *model;
    NSArray *keys;
    NSDictionary *mod;
    
    for( NSManagedObject *modd in self.calendarItems )
    {
        keys = [[[modd entity] attributesByName] allKeys];
        mod = [modd dictionaryWithValuesForKeys:keys];
        
        if( [[mod valueForKey:@"id"] isEqualToString:id] ) model = modd;
    }
    
    if( model )
    {
        NSString *priceString = [NSString stringWithFormat:@"%@", [attributes valueForKey:@"price"]];
        NSString *admission = [priceString isEqualToString:@"0"] ? @"Free" : [attributes valueForKey:@"admission"];
        
        [model setValue:[attributes valueForKey:@"name"] forKey:@"name"];
        [model setValue:[attributes valueForKey:@"short_description"] forKey:@"short_description"];
        [model setValue:[attributes valueForKey:@"startTime"] forKey:@"startTime"];
        [model setValue:[attributes valueForKey:@"endTime"] forKey:@"endTime"];
        [model setValue:[self.Utils parseUTCDate:[attributes valueForKey:@"startTime"]  pattern:@"EEEE MMM d @ h:mm a"] forKey:@"dateString"];
        [model setValue:[[attributes valueForKey:@"tags"] componentsJoinedByString:@", "] forKey:@"tags"];
        [model setValue:admission forKey:@"admission"];
        [model setValue:[attributes valueForKey:@"address"] forKey:@"address"];
        [model setValue:[self.Utils utcToDate:[attributes valueForKey:@"startTime"]] forKey:@"starTime"];
        NSError *error = nil;
        if (![self.context save:&error]) NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

@end
