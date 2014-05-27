//
//  EVEDescriptionViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/19/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEDescriptionViewController.h"
#import "EVEUtils.h"

@interface EVEDescriptionViewController ()
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *noteLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;

@property (nonatomic, strong) EVEUtils *Utils;
@end

@implementation EVEDescriptionViewController

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
    self.title = @"Description";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f]}];
    
    self.titleLabel.text = self.headline;
    self.subTitleLabel.text = self.subHeadline;
    self.bodyLabel.text = self.body;
    self.noteLabel.text = self.note;

    UIBarButtonItem * closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    closeButton.tintColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    self.navigationItem.leftBarButtonItem = closeButton;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** **/
-( void )dismiss
{
    NSLog(@"dismiss me");
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
