//
//  EVEAnnotation.h
//  eve
//
//  Created by Teddy Moussignac on 4/6/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface EVEAnnotation : NSObject <MKAnnotation>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, strong) NSDictionary *config;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL hasDetailView;
@property (nonatomic) BOOL hasDirection;
@property (nonatomic) BOOL isOn;

-( id ) initWithTitle:( NSString *)newTitle subTitle:(NSString *)subTitle location:(CLLocationCoordinate2D)location;
-( MKAnnotationView *) annotationView;

@end
