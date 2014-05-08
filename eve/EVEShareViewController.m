//
//  EVEShareViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/24/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEShareViewController.h"
#import "EVEUtils.h"

@interface EVEShareViewController ()
@property (nonatomic, strong) EVEUtils *Utils;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *header;
@property (nonatomic, strong) UILabel *subHeader;
@end

@implementation EVEShareViewController

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
    [self initTitleView];
}

-( void ) initConfig
{
    self.Utils = [[EVEUtils alloc] init];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationController.navigationBar setTranslucent:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setBarTintColor:[self.Utils.theme valueForKey:@"themeColor"]];
    self.navigationController.navigationBar.tintColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeView)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:nil];
    
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
    self.header.text = [NSString stringWithFormat:@"%@, %@", [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"SubLocality"], [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"SubAdministrativeArea"]];
    self.subHeader.text = [NSString stringWithFormat:@"%@, %@", [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"City"], [[self.Utils.Defaults objectForKey:@"userAddress"] objectForKey:@"State"]];
}

-( void )closeView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
