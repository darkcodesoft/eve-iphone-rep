//
//  EVEAnnotation.m
//  eve
//
//  Created by Teddy Moussignac on 4/6/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVEAnnotation.h"

/** **/
@implementation EVEAnnotation

/** **/
-( id ) initWithTitle:(NSString *)newTitle subTitle:(NSString *)subTitle location:(CLLocationCoordinate2D)location
{
    self = [super init];
    if (self != nil){
        _coordinate = location;
        _title = newTitle;
        _subtitle = subTitle;
    }
    
    return self;
}

/** **/
-( MKAnnotationView *) annotationView
{
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"myAnnotation"];
    annotationView.enabled = YES;
    annotationView.image = [UIImage imageNamed:@"pin-large"];
    
    UIView *theme = [[UIView alloc] initWithFrame:CGRectMake(10, 6, 11, 11)];
    theme.layer.cornerRadius = 5;
    theme.backgroundColor = [UIColor colorWithRed:0/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f];
    
    [annotationView addSubview:theme];
    
    if( self.hasDetailView )
    {
        [theme setFrame:CGRectMake(8, 5, 8, 8)];
        annotationView.canShowCallout = YES;
        annotationView.image = [UIImage imageNamed:@"pin"];
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoDark];
    }
    
    if( self.hasDirection )
    {
        
    }
    
    return annotationView;
}

@end
