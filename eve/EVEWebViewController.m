//
//  EVEWebViewController.m
//  eve
//
//  Created by Teddy Moussignac on 5/26/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEWebViewController.h"

@interface EVEWebViewController () <UIWebViewDelegate>
@property ( nonatomic, weak ) IBOutlet UIWebView *webView;
@property ( nonatomic, weak ) IBOutlet UIView *screen;
@property ( nonatomic, weak ) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation EVEWebViewController

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
    [self loadWebResource];
}

-( void ) initConfig
{
    self.title = @"Tickets";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f]}];

    UIBarButtonItem * closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeView)];
    closeButton.tintColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    self.navigationItem.leftBarButtonItem = closeButton;
}

-( void ) loadWebResource
{
    NSURL *url = [NSURL URLWithString:self.url];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
    [self.spinner startAnimating];
    [self.spinner setAlpha:1];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.spinner setAlpha:0];
    } completion:^(BOOL finished) {
        //Completion Block
        [self.spinner stopAnimating];
        [UIView animateWithDuration:.6 delay:0.3 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self.screen setAlpha:0];
        } completion:nil];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** **/
-( void )closeView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
