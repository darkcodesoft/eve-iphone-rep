//
//  EVEUserViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/24/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEUserViewController.h"
#import "EVEUtils.h"

@interface EVEUserViewController ()
@property (nonatomic, strong) EVEUtils *Utils;
@end

@implementation EVEUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initConfig];
}

-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    
    self.navigationItem.title = @"Faves";
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.leftBarButtonItem = editButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(initPostController)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    NSArray *itemArray = [NSArray arrayWithObjects: @"Saved", @"Shared", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, 0, 150, 30);
   // segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self
                         action:@selector(pickOne:)
               forControlEvents:UIControlEventValueChanged];
	//[self.view addSubview:segmentedControl];
    self.navigationItem.titleView = segmentedControl;
}

-( void ) initPostController
{
    [self.Utils initPostController:self];
}

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

@end
