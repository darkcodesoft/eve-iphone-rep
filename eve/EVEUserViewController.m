//
//  EVEUserViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/24/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

const float filterViewHeight = 0;

#import "EVEUserViewController.h"
#import "EVEUtils.h"
#import "TPAppDelegate.h"
#import "EVECell.h"
#import "EVEDetailViewController.h"
#import "EVEFilterUITextField.h"
#import <EventKit/EventKit.h>

static NSString *CellID = @"list-table-cell";

@interface EVEUserViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) EVEUtils *Utils;
@property ( nonatomic, strong ) UIView *titleView;
@property ( nonatomic, strong ) UILabel *header;
@property ( nonatomic, strong ) UILabel *subHeader;
@property (nonatomic, strong) UIRefreshControl *calendarListrefreshControl;
@property (nonatomic, strong) TPAppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) UITableView *TableView;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, weak) IBOutlet UIView *filterView;
@property (nonatomic, weak) IBOutlet EVEFilterUITextField *searchTextField;
@property (nonatomic, weak) IBOutlet UITableView *resultList;
@property (nonatomic, strong) NSArray *collection;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) BOOL filterOpen;
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
    [self drawFilter];
    [self retrieveModels];
    
    // init listeners
    [self initListeners];
}

/** **/
-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    
    self.navigationItem.title = @"Calendar";
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleFilter)];
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
-( void ) initListeners
{
    // cityView listner
    UITapGestureRecognizer *titleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFilter)];
    [self.titleView addGestureRecognizer:titleTap];
}

/** **/
-( void ) removeCalendarItem:(NSIndexPath *)path
{
    NSManagedObject *model = [self.calendarItems objectAtIndex:path.row];
    NSArray *keys = [[[model entity] attributesByName] allKeys];
    NSDictionary *mod = [model dictionaryWithValuesForKeys:keys];
    
    [self.calendarList beginUpdates];
    [self.calendarList deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
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
    
    [self.calendarList endUpdates];
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
    else
    {
        self.calendarItems = objects;
        self.collection = objects;
    }
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
    //[self calendarListRefresh];
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
    
    NSDictionary *model = (NSDictionary *)[self.collection objectAtIndex:indexPath.row];
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
    
    if( tableView == self.calendarList )
    {
        return cell;
    }
    
    else return cell;
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
    return [self.collection count];
}

/** **/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *model = (NSDictionary *)[self.collection objectAtIndex:indexPath.row];
    
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

/** **/
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self toggleFilter];
    [textField resignFirstResponder];
    return YES;
}


/** **/
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

-(IBAction)textFieldDidChange:(id)sender
{
    if( sender == self.searchTextField )
    {
        [self.timer invalidate];
        
        if( self.searchTextField.text.length > 2 )
        {
            self. timer = [NSTimer scheduledTimerWithTimeInterval:0.0
                                             target:self
                                           selector:@selector(initFilter)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}

/** **/
-( void )initFilter
{
    NSString *keyword = self.searchTextField.text;
    NSPredicate *npredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", keyword];
    NSPredicate *dpredicate = [NSPredicate predicateWithFormat:@"SELF.short_description contains[c] %@", keyword];
    NSPredicate *apredicate = [NSPredicate predicateWithFormat:@"SELF.address contains[c] %@", keyword];
    NSPredicate *adpredicate = [NSPredicate predicateWithFormat:@"SELF.admission contains[c] %@", keyword];
    NSPredicate *dapredicate = [NSPredicate predicateWithFormat:@"SELF.dateString contains[c] %@", keyword];
    NSPredicate *tapredicate = [NSPredicate predicateWithFormat:@"SELF.tags contains[c] %@", keyword];
    
    NSCompoundPredicate *predicate = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:npredicate,dpredicate,apredicate,adpredicate,dapredicate,tapredicate, nil]];
    
    NSArray *objects = [self.calendarItems filteredArrayUsingPredicate:predicate];
 
    if ( [objects count] == 0 )
    {
         NSLog( @"No matches" );
        self.collection = self.calendarItems;
    }
    else
    {
        self.collection = [NSMutableArray arrayWithArray:objects];
        CGRect frame = [self.filterView frame];
        frame.origin.y = filterViewHeight;
        
        [self.filterView setFrame:frame];
        [self.calendarList setFrame:CGRectMake(0, 66, self.calendarList.frame.size.width, self.calendarList.frame.size.height)];
        
        int64_t delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.calendarList reloadData];
            [self hideFilter];
        });
    }
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
-( void ) drawFilter
{
    self.filterOpen = NO;
    [self.filterView setHidden:YES];
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
        [self.searchTextField resignFirstResponder];
        [self.calendarList setFrame:CGRectMake(0, 0, self.calendarList.frame.size.width, self.calendarList.frame.size.height)];
    } completion:^(BOOL finished){
       
        if( self.searchTextField.text.length == 0 )
        {
            self.collection = self.calendarItems;
            
            int64_t delayInSeconds = 0.1f;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.calendarList reloadData];
            });
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
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.filterView setFrame:frame];
        [self.calendarList setFrame:CGRectMake(0, 66, self.calendarList.frame.size.width, self.calendarList.frame.size.height)];
    } completion:^(BOOL finished){
        [self.searchTextField becomeFirstResponder];
    }];
}

@end
