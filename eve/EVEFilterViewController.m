//
//  EVEFilterViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/10/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

const float datePickerViewHeight = 160;
const float cityListViewHeight = 200;
static NSString *CellID = @"city-table-cell";

#import "EVEFilterViewController.h"
#import "EVETableViewController.h"
#import "EVEFilterUITextField.h"
#import "EVEUtils.h"
#import "EVECell.h"

@interface EVEFilterViewController () <UITextFieldDelegate, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property ( nonatomic, weak ) IBOutlet UIView *container;
@property ( nonatomic, weak ) IBOutlet UIView *wrapper;
@property ( nonatomic, weak ) IBOutlet UIScrollView *scrollView;
@property ( nonatomic, weak ) IBOutlet UISegmentedControl *dateControl;
@property ( nonatomic, weak ) IBOutlet UIScrollView *dateControlScroll;
@property ( nonatomic, weak ) IBOutlet UIDatePicker *datePicker;
@property ( nonatomic, weak ) IBOutlet UITableView *cityList;
@property ( nonatomic, weak ) IBOutlet UILabel *cityLabel;
@property ( nonatomic, weak ) IBOutlet UIButton *submitButton;
@property ( nonatomic, weak ) IBOutlet UIView *dateControlView;
@property ( nonatomic, weak ) IBOutlet UIView *datePickerView;
@property ( nonatomic, weak ) IBOutlet UIView *keywordView;
@property ( nonatomic, weak ) IBOutlet UIView *cityView;
@property ( nonatomic, weak ) IBOutlet UIView *cityListView;
@property ( nonatomic, weak ) IBOutlet UIView *submitButtonView;
@property ( nonatomic, weak ) IBOutlet EVEFilterUITextField *keywordTextField;

@property ( nonatomic, strong ) NSArray *cities;
@property ( nonatomic, strong ) NSString *keyword;
@property ( nonatomic, strong ) NSDictionary *city;
@property ( nonatomic, strong ) NSString *region;
@property ( nonatomic, strong ) NSString *country;
@property ( nonatomic, strong ) NSString *venue;
@property ( nonatomic, strong ) EVEUtils *Utils;

@property ( nonatomic ) BOOL datePickerIsOpen;
@property ( nonatomic ) BOOL cityListIsOpen;

-( IBAction )dateControlSelected:(id)sender;

@end

@implementation EVEFilterViewController

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
    [self initConfig];
    [self initForm];
    [self initListeners];
}

/** **/
-( void ) initConfig
{
    self.Utils = [EVEUtils new];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Search";
    
    [self.navigationController.navigationBar setTranslucent:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setBarTintColor:[self.Utils.theme valueForKey:@"themeColor"]];
    self.navigationController.navigationBar.tintColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
}

/** **/
-( void ) initForm
{
    // scrollView
    
    // keyword
    [self.keywordTextField setDelegate:self];
    [self.keywordTextField becomeFirstResponder];
    
    // submit button
    self.submitButton.layer.cornerRadius = 5;
    self.submitButton.backgroundColor = [self.Utils.theme valueForKey:@"themeColor"];
    [self.submitButton addTarget:self action:@selector(applySettings) forControlEvents:UIControlEventTouchUpInside];
    
    // city list
    self.cityListIsOpen = NO;
    
    // date picker settings
    self.datePickerIsOpen = NO;
    
    //self.dateControl.tintColor = [self.Utils.theme valueForKey:@"themeColor"];
    //self.dateControl.backgroundColor = [self.Utils.theme valueForKey:@"themeColor"];
    //self.dateControl.tintColor = [UIColor whiteColor];
    self.dateControlScroll.contentSize = CGSizeMake( self.dateControl.bounds.size.width + 40, 40 );
    
    [self.datePicker addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
    
    // update frames
    [self updateScroll];
    
    // date
    [self setQueryStartTimeTo:[NSDate date]];
    
    // cityList
    CGRect ctframe = [self.cityList frame];
    ctframe.size.height = cityListViewHeight;
    
    [self.cityList setFrame:ctframe];
    
    NSArray *cityArray = [NSArray arrayWithObjects:
                   @{@"label" : @"New York City, NY, USA", @"City": @"New York", @"State":@"NY", @"Country":@"United States", @"lat" : @"40.774643100000000000", @"long" : @"-73.970196200000030000"},
                   @{@"label" : @"Manhattan, NY, USA", @"City": @"Manhattan", @"State":@"NY", @"Country":@"United States" , @"lat" : @"40.774643100000000000", @"long" : @"-73.970196200000030000"},
                   @{@"label" : @"Brooklyn, NY, USA", @"City": @"Brooklyn", @"State":@"NY", @"Country":@"United States", @"lat" : @"40.6602037", @"long" : @"-73.9689558"},
                   @{@"label" : @"Miami, FL, USA", @"City": @"Miami", @"State":@"FL", @"Country":@"United States", @"lat" : @"25.771251300000000000", @"long" : @"-80.191872800000000000"},
                   @{@"label" : @"Las Vegas, NV, USA", @"City": @"Las Vegas", @"State":@"NV", @"Country":@"United States", @"lat" : @"36.114646000000000000", @"long" : @"-115.172816000000010000"},
                   @{@"label" : @"Los Angeles, CA, USA", @"City": @"Los Angeles", @"State":@"CA", @"Country":@"United States", @"lat" : @"34.052234200000000000", @"long" : @"-118.243684900000000000"},
                   @{@"label" : @"San Francisco, CA, USA", @"City": @"San Francisco", @"State":@"CA", @"Country":@"United States", @"lat" : @"37.774929500000000000", @"long" : @"-122.419415500000010000"},
                   @{@"label" : @"London, ENG, GB", @"City": @"London", @"State":@"ENG", @"Country":@"Great Britain", @"lat" : @"51.508129000000000000", @"long" : @"-0.128005000000030120"},
                   @{@"label" : @"Paris, IDF, FR", @"City": @"Paris", @"State":@"IDF", @"Country":@"France", @"lat" : @"48.856614000000000000", @"long" : @"2.352221900000017700"},
                   @{@"label" : @"Sydney, NSW, AUS", @"City": @"Sydney", @"State":@"NSW", @"Country":@"Australia", @"lat" : @"-33.873651000000000000", @"long" : @"151.206889600000070000"},
                   @{@"label" : @"Hong Kong, TW, CH", @"City": @"Hong Kong", @"State":@"CH", @"Country":@"China", @"lat" : @"22.312968700000000000", @"long" : @"114.042110800000050000"},
                   @{@"label" : @"Tokyo, TK, JP", @"City": @"Tokyo", @"State":@"TK", @"Country":@"Japan", @"lat" : @"35.689487500000000000", @"long" : @"-139.691706399999930000"},
                   nil];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    self.cities = [cityArray sortedArrayUsingDescriptors:sortDescriptors];
    
    CAGradientLayer *alphaGradientLayer = [CAGradientLayer layer];
    NSArray *colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0 alpha:0] CGColor],
                       (id)[[UIColor colorWithWhite:0 alpha:1] CGColor],
                       nil];
    
    [alphaGradientLayer setColors:colors];
    // Start the gradient at the bottom and go almost half way up.
    [alphaGradientLayer setStartPoint:CGPointMake(0, 1)];
    [alphaGradientLayer setEndPoint:CGPointMake(0, 0.55)];
    [alphaGradientLayer setFrame:[self.cityList frame]];
    //[[self.cityListView layer] setMask:alphaGradientLayer];
    
    // get previous city
    NSMutableDictionary *queryCity = [(EVETableViewController *) self.delegate queryCity];
    
    if( queryCity )
    {
        [self setQueryCity:queryCity];
        self.cityLabel.text = [queryCity valueForKey:@"label"];
    }
    else self.cityLabel.text = [[self.cities objectAtIndex:0] valueForKey:@"label"];
}

/** **/
-( void ) initListeners
{
    // cityView listner
    UITapGestureRecognizer *cityViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCityList)];
    [self.cityView addGestureRecognizer:cityViewTap];
    
    // keyboard listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateScroll)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

/** **/
-( void ) updateScroll
{
    CGRect frame = self.view.frame;
    frame.size.height = self.view.frame.size.height - 63;
    NSArray *views = [NSArray arrayWithArray:[self.wrapper subviews]];
    float heights = 0;

    for( UIView *view in views )
    {
        heights += view.frame.size.height;
    }
    
    if( heights > frame.size.height ) frame.size.height = heights + 80;
    self.scrollView.contentSize = frame.size;
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
            [self hideDatePicker];
            [self setQueryStartTimeTo:date];
            break;
        case 2:
            [self hideDatePicker];
            [self setQueryStartTimeTo:[self.Utils getNextWeekend]];
            break;
        case 3:
            [self showDatePicker];
            break;
        default:
            [self hideDatePicker];
            [self setQueryStartTimeTo:date];
            break;
    }
}

/** **/
-( void ) toggleDatePicker
{
    if( self.datePickerIsOpen ) [self hideDatePicker];
    else [self showDatePicker];
}

/** **/
-( void ) showDatePicker
{
    if( self.datePickerIsOpen ) return;
    self.datePickerIsOpen = YES;
    
    CGRect datePickerViewFrame = [self.datePickerView frame];
    CGRect keywordViewFrame = [self.keywordView frame];
    CGRect cityViewFrame = [self.cityView frame];
    CGRect cityListViewFrame = [self.cityListView frame];
    CGRect submitButtonViewFrame = [self.submitButtonView frame];
    
    datePickerViewFrame.size.height = datePickerViewHeight;
    keywordViewFrame.origin.y = self.keywordView.frame.origin.y + datePickerViewHeight;
    cityViewFrame.origin.y = self.cityView.frame.origin.y + datePickerViewHeight;
    cityListViewFrame.origin.y = self.cityListView.frame.origin.y + datePickerViewHeight;
    submitButtonViewFrame.origin.y = self.submitButtonView.frame.origin.y + datePickerViewHeight;
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.datePickerView setFrame:datePickerViewFrame];
        [self.keywordView setFrame:keywordViewFrame];
        [self.cityView setFrame:cityViewFrame];
        [self.cityListView setFrame:cityListViewFrame];
        [self.submitButtonView setFrame:submitButtonViewFrame];
        
    } completion:^(BOOL finished) {
        //Completion Block
        [self updateScroll];
    }];
    // set query date
    [self setQueryStartTimeTo:self.datePicker.date];
}

/** **/
-( void ) hideDatePicker
{
    if( !self.datePickerIsOpen ) return;
    self.datePickerIsOpen = NO;
    
    CGRect datePickerViewFrame = [self.datePickerView frame];
    CGRect keywordViewFrame = [self.keywordView frame];
    CGRect cityViewFrame = [self.cityView frame];
    CGRect cityListViewFrame = [self.cityListView frame];
    CGRect submitButtonViewFrame = [self.submitButtonView frame];
    
    datePickerViewFrame.size.height = 0;
    keywordViewFrame.origin.y = self.keywordView.frame.origin.y - datePickerViewHeight;
    cityViewFrame.origin.y = self.cityView.frame.origin.y - datePickerViewHeight;
    cityListViewFrame.origin.y = self.cityListView.frame.origin.y - datePickerViewHeight;
    submitButtonViewFrame.origin.y = self.submitButtonView.frame.origin.y - datePickerViewHeight;
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.datePickerView setFrame:datePickerViewFrame];
        [self.keywordView setFrame:keywordViewFrame];
        [self.cityView setFrame:cityViewFrame];
        [self.cityListView setFrame:cityListViewFrame];
        [self.submitButtonView setFrame:submitButtonViewFrame];
        
    } completion:^(BOOL finished) {
        //Completion Block
        [self updateScroll];
    }];
}

/** **/
-( void ) toggleCityList
{
    if( self.cityListIsOpen ) [self hideCityList];
    else [self showCityList];
    
    [self.cityView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.05]];
        
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        self.cityView.backgroundColor = [UIColor whiteColor];
    } completion:^(BOOL finished) {
        //Completion Block
    }];
}

/** **/
-( void ) showCityList
{
    if( self.cityListIsOpen ) return;
    self.cityListIsOpen = YES;
    
    CGRect submitButtonFrame = [self.submitButtonView frame];
    CGRect cityListViewFrame = [self.cityListView frame];
    
    cityListViewFrame.size.height = cityListViewHeight;
    submitButtonFrame.origin.y += cityListViewHeight;
    
    [self.keywordTextField resignFirstResponder];
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.submitButtonView setFrame:submitButtonFrame];
        [self.cityListView setFrame:cityListViewFrame];
        
    } completion:^(BOOL finished) {
        //Completion Block
        [self updateScroll];
    }];
}

/** **/
-( void ) hideCityList
{
    if( !self.cityListIsOpen ) return;
    self.cityListIsOpen = NO;
    
    CGRect submitButtonFrame = [self.submitButtonView frame];
    CGRect cityListViewFrame = [self.cityListView frame];
    
    cityListViewFrame.size.height = 0;
    submitButtonFrame.origin.y -= cityListViewHeight;
    
    [UIView animateWithDuration:.8 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        //Animations
        [self.submitButtonView setFrame:submitButtonFrame];
        [self.cityListView setFrame:cityListViewFrame];
        
    } completion:^(BOOL finished) {
        //Completion Block
        [self updateScroll];
    }];
}

/** **/
-( void )dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/** **/
-( void )applySettings
{
    [self setQueryKeyword];
    
    [(EVETableViewController *) self.delegate updateCollection];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/** **/
- (void) datePickerChanged:(id)sender{
    // handle date changes
    [self setQueryStartTimeTo:[(UIDatePicker *)sender date]];
    [self.dateControl setTitle:[self.Utils formatDate:[(UIDatePicker *)sender date] pattern:@"M . d . YY"] forSegmentAtIndex:3];
}

/** **/
-( void ) setQueryStartTimeTo:( NSDate *) date
{
    [(EVETableViewController *) self.delegate setQueryTimestamp:[self.Utils formatDate:date pattern:@"yyyyMMddHHmmss" ]];
}

/** **/
-( void ) setQueryCity:( NSMutableDictionary *) city
{
    self.city = [NSMutableDictionary dictionaryWithDictionary:city];
    [(EVETableViewController *) self.delegate setQueryCity:city];
    [self.cityLabel setText:[NSString stringWithFormat:@"%@", [city valueForKey:@"label"]]];
    //[self hideCityList];
}

/** **/
-( void ) setQueryKeyword
{
    [(EVETableViewController *) self.delegate setQueryKeyword:self.keywordTextField.text];
}

/** **/
- (void)keyboardWasShown:(NSNotification *)notification
{
    // Get the size of the keyboard.
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    //your other code here..........
    CGRect frame = self.scrollView.frame;
    frame.size.height = self.scrollView.frame.size.height + keyboardSize.height;
    self.scrollView.contentSize = frame.size;
}

/** **/
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


/** **/
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

// number Of Components
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
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
    return [self.cities count];
}

/**
 * @desc setup table view cell
 **/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dynamic fix identifier for fix table
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];

    if (cell == nil)
    {
        NSDictionary *model = (NSDictionary *)[self.cities objectAtIndex:indexPath.row];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"%@-%i", CellID, [indexPath row]]];
        
        UIView *selectedBackgroundViewForCell = [UIView new];
        [selectedBackgroundViewForCell setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.05]];
        //cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.05];
        cell.backgroundColor = nil;
        cell.selectedBackgroundView = selectedBackgroundViewForCell;
        cell.userInteractionEnabled = YES;
        
        NSString *label = [model valueForKey:@"label"] ? [model valueForKey:@"label"] : @"";
        [cell.textLabel setText:label];
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
        [cell.textLabel setTextColor:[UIColor whiteColor]];
    }
    
    return cell;
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *config = (NSMutableDictionary *)[self.cities objectAtIndex:indexPath.row];
    [self setQueryCity:config];
}

/**
 * @desc set tableView height value
 **/
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
