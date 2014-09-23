//
//  LocationSettingViewController.m
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/18.
//  Copyright (c) 2014年 hyde. All rights reserved.
//

#import "LocationSettingViewController.h"
#import "AddNewEventViewController.h"
#import "ViewController.h"
#import "GeoFencingItemViewController.h"

@interface LocationSettingViewController ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UISlider *slider;
@end

@implementation LocationSettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.geocoder)
        self.geocoder = [CLGeocoder new];

    // navigation buttons.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    if (self.isModifyMode) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                      action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    // set up mapView.
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    //self.mapView.showsUserLocation = YES;
    
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    //self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = 10;
    // for iOS 8+
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];
    
    if (self.isModifyMode)
        [self updatePinPositionAndRadius:self.coordinate automaticScale:YES];
    else
        [self.locationManager startUpdatingLocation];
    
    // add radius ajust slider.
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20.0, self.view.frame.size.height-70.0, self.view.frame.size.width-80.0, 44.0)];
    [slider addTarget:self action:@selector(radiusChanged:) forControlEvents:UIControlEventValueChanged];
    slider.value = self.radius;
    slider.minimumValue = 100.0;
    slider.maximumValue = 1000.0; // 1km
    self.slider = slider;
    [self.mapView addSubview:self.slider];
    
    // add gps button.
    UIImage *image = [[UIImage imageNamed:@"LocationArrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *locationControl = [[UIButton alloc] initWithFrame:CGRectMake(
                                                                             self.view.frame.size.width - image.size.width - 30.0,
                                                                             self.view.frame.size.height-60.0,
                                                                             image.size.width * 2.0,
                                                                             image.size.height * 2.0
                                                                             )];
    [locationControl addTarget:self action:@selector(locationButtonTapped:) forControlEvents:UIControlEventTouchDown];
    [locationControl setImage:image forState:UIControlStateNormal];
    locationControl.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    locationControl.layer.cornerRadius = 5.0;
    locationControl.layer.borderColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;
    locationControl.layer.borderWidth = 1.0;
    [self.mapView addSubview:locationControl];
    [self.view addSubview:self.mapView];
    
    // add gesture.
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    gesture.delegate = self;
    [self.mapView addGestureRecognizer:gesture];
}

- (void)longPressed:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long pressed");
        // convert the touch point to a CLLocationCoordinate & geocode
        CGPoint touchPoint = [gesture locationInView:self.mapView];
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint
                                         toCoordinateFromView:self.mapView];
        [self reverseGeocodeCoordinate:coordinate];
    }
}

- (void)reverseGeocodeCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self.geocoder.isGeocoding)
        [self.geocoder cancelGeocode];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                      longitude:coordinate.longitude];
    
    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
                            if (!error)
                                [self processReverseGeocodingResults:placemarks];
                        }];
}

- (void)processReverseGeocodingResults:(NSArray *)placemarks {
    
    if (placemarks.count == 0)
        return;
    
    CLPlacemark *placemark = [placemarks objectAtIndex:0];
    [self updatePinPositionAndRadius:placemark.location.coordinate automaticScale:NO];
    
//    NSString *message = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO); // requires AddressBookUI framework
}

- (void)updatePinPositionAndRadius:(CLLocationCoordinate2D)coordinate automaticScale:(BOOL)autoScale
{
    self.coordinate = coordinate;
    MKCoordinateSpan span;
    if (!autoScale) {
        span = self.mapView.region.span;
    } else {
        CLLocationDegrees degree = 1 / 111.0 / 1000.0 * self.radius * 3;
        span = MKCoordinateSpanMake(degree, degree);
    }
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMake(self.coordinate, span);
    [self.mapView setRegion:coordinateRegion animated:YES];
    
    if (self.pin) {
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView removeOverlays:self.mapView.overlays];
    }
    
    // add pin
    self.pin = [[MKPointAnnotation alloc] init];
    self.pin.coordinate = self.coordinate;
    [self.mapView addAnnotation:self.pin];
    
    // add circle
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:self.coordinate radius:self.radius];
    [self.mapView addOverlay:circle];
}

- (void)locationButtonTapped:(UIControl *)control
{
    NSLog(@"location button taped");
    [self.locationManager startUpdatingLocation];
}

- (void)radiusChanged:(UISlider *)slider
{
    NSLog(@"radius changed to = %f", slider.value);
    self.radius = slider.value;
    // remove circle overlay.
    [self.mapView removeOverlays:self.mapView.overlays];
    
    //// recreate circle annotation.
    // re-set circle overlay.
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:self.coordinate radius:self.radius];
    [self.mapView addOverlay:circle];
    
    // re-set the new span.
    CLLocationDegrees degree = 1 / 111.0 / 1000.0 * self.radius * 3;
    MKCoordinateSpan span = MKCoordinateSpanMake(degree, degree);
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMake(self.coordinate, span);
    [self.mapView setRegion:coordinateRegion animated:YES];
}

- (void)save:(id)sender
{
    if (!self.isModifyMode) {
        AddNewEventViewController *prevVC = self.navigationController.viewControllers[self.navigationController.viewControllers.count-2];
        NSTimeInterval unixTime = [[NSDate date] timeIntervalSince1970];
        NSString *identifier = [NSString stringWithFormat:@"%lld", (long long)unixTime];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"Name"] = prevVC.name;
        dict[@"Latitude"] = [NSNumber numberWithDouble:self.coordinate.latitude];
        dict[@"Longitude"] = [NSNumber numberWithDouble:self.coordinate.longitude];
        dict[@"Radius"] = [NSNumber numberWithDouble:self.radius];
        dict[@"ExitedTrigger"] = @YES;
        dict[@"Enabled"] = @YES;
        dict[@"TimeFilterEnabled"] = @NO;
        dict[@"Identifier"] = identifier;
        dict[@"StartFilterTime"] = @"00:00";
        dict[@"EndFilterTime"] = @"00:00";
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[defaults arrayForKey:@"GeoItems"] mutableCopy];
        if (!array) {
            array = [NSMutableArray array];
            array[0] = dict;
        } else
            [array insertObject:dict atIndex:0];
        
        [defaults setObject:array forKey:@"GeoItems"];
        NSLog(@"saved = %d", [defaults synchronize]);
        
        ViewController *vc = (ViewController *)((UINavigationController *)self.presentingViewController).topViewController;
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:self.coordinate radius:self.radius identifier:identifier];
        [vc addNewGeoFencingItem:prevVC.name region:region];
    } else {
        // update geoFencingItems.
        NSArray *VCs = [(UINavigationController *)self.presentingViewController viewControllers];
        GeoFencingItemViewController *vc = VCs[VCs.count-1];
        NSMutableDictionary *dict = [vc.rootVC.geoFencingItems[vc.selectedRow] mutableCopy];
        CLCircularRegion *region = dict[@"Location"];
        NSString *identifier = region.identifier;
        CLCircularRegion *newRegion = [[CLCircularRegion alloc] initWithCenter:self.coordinate radius:self.radius identifier:identifier];
        vc.rootVC.geoFencingItems[vc.selectedRow][@"Location"] = newRegion;
        [vc.tableView reloadData];
        
        // modify monitoring location.
        if ([vc.rootVC.geoFencingItems[vc.selectedRow][@"Enabled"] boolValue]) {
            NSLog(@"updating location...");
            [vc.rootVC.locationManager startMonitoringForRegion:newRegion];
        }
        
        // update UserDefaults.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[defaults arrayForKey:@"GeoItems"] mutableCopy];
        NSMutableDictionary *dict2 = [array[vc.selectedRow] mutableCopy];
        dict2[@"Latitude"] = [NSNumber numberWithDouble:self.coordinate.latitude];
        dict2[@"Longitude"] = [NSNumber numberWithDouble:self.coordinate.longitude];
        dict2[@"Radius"] = [NSNumber numberWithDouble:self.radius];
        array[vc.selectedRow] = dict2;
        [defaults setObject:array forKey:@"GeoItems"];
        NSLog(@"saved = %d", [defaults synchronize]);
    }
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [manager stopUpdatingLocation];
    // update center.
    CLLocation *location = locations[0];
    [self updatePinPositionAndRadius:location.coordinate automaticScale:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    static NSString *identifier = @"PinAnnotationIdentifier";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView
                                                           dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!pinView) {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:identifier];
        pinView.animatesDrop = YES;
        pinView.draggable = YES;
        return pinView;
    }
    pinView.annotation = annotation;
    pinView.draggable = YES;
    return pinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateStarting) {
        // remove circle overlay.
        [mapView removeOverlays:mapView.overlays];
    }
    
    if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateNone) {
        self.coordinate = annotationView.annotation.coordinate;
        NSLog(@"Pin dropped at %f,%f", self.coordinate.latitude, self.coordinate.longitude);

        // re-set circle overlay.
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:self.coordinate radius:self.radius];
        [mapView addOverlay:circle];

        // move to center after delay.
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [mapView setCenterCoordinate:self.coordinate animated:YES];
        });
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circle = [[MKCircleRenderer alloc] initWithCircle:overlay];
//        circle.strokeColor = [UIColor blueColor];
        circle.fillColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        circle.alpha = 0.2;
        return circle;
    } else {
        return nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"%@", touch.view);
    if (touch.view == self.slider)
        return NO;
    return YES;
}

@end
