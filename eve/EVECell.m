//
//  EVECell.m
//  eve
//
//  Created by Teddy Moussignac on 4/16/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "EVECell.h"
#import <MapKit/MapKit.h>
#import "EVEUtils.h"

@interface EVECell ()
@property (nonatomic, strong) EVEUtils *Utils;
@end
@implementation EVECell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Helpers
    }
    
    return self;
}

/** **/
-( void ) setDistanceLabelText
{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    MKPlacemark *destinationMark = [[MKPlacemark alloc] initWithCoordinate:location addressDictionary:nil];
    MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationMark];

    [self findDistanceFrom:[MKMapItem mapItemForCurrentLocation] to:destinationItem];
}

/** **/
-( void )findDistanceFrom:(MKMapItem *)source to:(MKMapItem *)destination
{
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = source;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    request.destination = destination;
    
    MKDirections *directionss = [[MKDirections alloc] initWithRequest:request];
    [directionss calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
        
        int res = (int)ceil(response.expectedTravelTime/60.0);
        NSString *eta = @"UNAVAILABLE";
        
        if( res > 0 ) eta = [[EVEUtils parseTime:res] uppercaseString];
        
        [self.distanceLabel setText:eta];
    }];
}

/** **/
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
