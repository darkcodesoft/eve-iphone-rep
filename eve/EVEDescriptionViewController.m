//
//  EVEDescriptionViewController.m
//  eve
//
//  Created by Teddy Moussignac on 4/19/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEDescriptionViewController.h"
#import "EVEUtils.h"

@interface EVEDescriptionViewController () <UIWebViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *noteLabel;
@property (nonatomic, weak) IBOutlet UILabel *bodyLabel;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIView *screen;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
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

    UIBarButtonItem * closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    closeButton.tintColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    [self loadWebResource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-( void ) loadWebResource
{
    [self.webView loadHTMLString:self.html baseURL:nil];
    [self.spinner startAnimating];
    [self.spinner setAlpha:1];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView animateWithDuration:.6 delay:0.0 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.spinner setAlpha:0];
    } completion:^(BOOL finished) {
        //Completion Block
        
        
        [webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"
         "script.type = 'text/javascript';"
         "script.text = \"function injectStyles() { "
         "document.body.style.fontFamily = 'helveticaNeue';"
         "document.body.style.padding = '5px';"
         "document.body.style.fontSize = '16px';"
         "document.body.style.overflow = 'hidden';"
         "for( var i = 0; i < document.images.length; i++ ){"
         "document.images[i].style.width = '300px';"
         "document.images[i].style.height = 'auto';"
         "document.images[i].style.display = 'block';"
         "document.images[i].margin = '10px auto';"
         "}"
         "}\";"
         "document.getElementsByTagName('head')[0].appendChild(script);"];
        
        [webView stringByEvaluatingJavaScriptFromString:@"injectStyles();"];
        
        [self.spinner stopAnimating];
        [UIView animateWithDuration:.6 delay:0.3 usingSpringWithDamping:.8 initialSpringVelocity:0.0 options:0 animations:^{
            [self.screen setAlpha:0];
        } completion:nil];
    }];
}

/** **/
-( void )dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
