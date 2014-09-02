//
//  LocationSettingViewController.h
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/18.
//  Copyright (c) 2014年 hyde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface LocationSettingViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) MKPointAnnotation *pin;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign, nonatomic) CLLocationDistance radius;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (assign, nonatomic) BOOL isModifyMode;

@end
