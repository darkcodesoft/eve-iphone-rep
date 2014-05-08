//
//  EVEDescriptionViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/19/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEDescriptionViewController.h"

@interface EVEDescriptionViewController ()
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *noteLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;
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
    self.titleLabel.text = self.headline;
    self.subTitleLabel.text = self.subHeadline;
    self.bodyLabel.text = self.body;
    self.noteLabel.text = self.note;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
