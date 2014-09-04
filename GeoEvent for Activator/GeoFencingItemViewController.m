//
//  GeoFencingItemViewController.m
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/17.
//  Copyright (c) 2014年 hyde. All rights reserved.
//
#import "ViewController.h"
#import "LocationSettingViewController.h"
#import "GeoFencingItemViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#if !DEBUG
#import <objcipc/objcipc.h>
#endif

@interface GeoFencingItemViewController ()

@end

@implementation GeoFencingItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"GeoEvent";
    
    UIView *v = [[UIView alloc] initWithFrame:self.view.bounds];
    v.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:v];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.rootVC = ((UINavigationController *)self.parentViewController).viewControllers[0];
    NSLog(@"selected geo item = %@", self.rootVC.geoFencingItems[self.selectedRow]);
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    NSString *name = self.rootVC.geoFencingItems[self.selectedRow][@"Name"];
                    cell.textLabel.text = @"Name";
                    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 195, 43)];
                    textField.text = name.length ? name : @"Name";
                    textField.delegate = self;
                    textField.textAlignment = NSTextAlignmentRight;
                    //textField.clipsToBounds = YES;
                    //textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    //textField.placeholder = @"placeholder";
                    cell.accessoryView = textField;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Enabled";
                    BOOL isEnabled = [(NSNumber *)self.rootVC.geoFencingItems[self.selectedRow][@"Enabled"] boolValue];
                    UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectZero];
                    sw.on = isEnabled;
                    [sw addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sw;
                    break;
                }
                case 2: {
                    BOOL isExitedTrigger = [(NSNumber *)self.rootVC.geoFencingItems[self.selectedRow][@"ExitedTrigger"] boolValue];
                    cell.textLabel.text = @"Trigger";
                    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"When I arrive...", @"When I leave..."]];
                    seg.selectedSegmentIndex = isExitedTrigger ? 1 : 0;
                    [seg addTarget:self
                                action:@selector(segmentValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = seg;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 1: {
            MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
            mapView.delegate = self;
            CLCircularRegion *region = self.rootVC.geoFencingItems[self.selectedRow][@"Location"];
            CLLocationCoordinate2D coordinate = region.center;
            CLLocationDegrees degree = 1 / 111.0 / 1000.0 * region.radius * 3;
            MKCoordinateSpan span = MKCoordinateSpanMake(degree, degree);
            MKCoordinateRegion coordinateRegion = MKCoordinateRegionMake(coordinate, span);
            [mapView setRegion:coordinateRegion animated:NO];
            mapView.zoomEnabled = NO;
            mapView.scrollEnabled = NO;
            // add pin
            MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
            pin.coordinate = coordinate;
            [mapView addAnnotation:pin];
            
            // add circle
            MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:region.radius];
            [mapView addOverlay:circle];
            
            [cell addSubview:mapView];
            
            UIControl *control = [[UIControl alloc] initWithFrame:mapView.bounds];
            [control addTarget:self action:@selector(locationTapped:) forControlEvents:UIControlEventTouchUpInside];
            [mapView addSubview:control];
            break;
        }
            
    }
    
    return cell;
}

- (void)locationTapped:(id)sender
{
    NSLog(@"location control taped %@", sender);
    LocationSettingViewController *vc = [LocationSettingViewController new];
    vc.isModifyMode = YES;
    CLCircularRegion *region = (CLCircularRegion *)self.rootVC.geoFencingItems[self.selectedRow][@"Location"];
    vc.radius = region.radius;
    vc.coordinate = region.center;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:^{}];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
        case 1:
            return 1;
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? @"Location" : @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            return 44.0;
        case 1:
            return 200.0;
        default:
            return 0;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length == 0) {
        textField.text = self.rootVC.geoFencingItems[self.selectedRow][@"Name"];
        // TODO:alert for iOS 8.
        return YES;
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *array = [[defaults arrayForKey:@"GeoItems"] mutableCopy];
        NSMutableDictionary *dict = [array[self.selectedRow] mutableCopy];
        dict[@"Name"] = textField.text;
        array[self.selectedRow] = dict;
        [defaults setObject:array forKey:@"GeoItems"];
        [defaults synchronize];
        // update events to activator.
#if !DEBUG
        [OBJCIPC sendMessageToSpringBoardWithMessageName:kGEUpdateEvents dictionary:nil replyHandler:nil];
#endif
        
        self.rootVC.geoFencingItems[self.selectedRow][@"Name"] = textField.text;
        [self.rootVC.tableView reloadData];
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)changeSwitch:(UISwitch *)sender
{
    NSLog(@"changed = %d", sender.isOn);
    [self updateUserDefaultAndTableItem:@"Enabled" toEnabled:sender.isOn];
    
     if (self.rootVC.isGeoFencingMonitoring)
         [self changeGeoFencing:sender.isOn];
}

- (void)changeGeoFencing:(BOOL)toOn
{
    CLCircularRegion *region = self.rootVC.geoFencingItems[self.selectedRow][@"Location"];
    if (toOn)
        [self.rootVC.locationManager startMonitoringForRegion:region];
    else
        [self.rootVC.locationManager stopMonitoringForRegion:region];
}

- (void)segmentValueChanged:(UISegmentedControl *)segment
{
    NSLog(@"changed = %ld", (long)segment.selectedSegmentIndex);
    [self updateUserDefaultAndTableItem:@"ExitedTrigger" toEnabled:segment.selectedSegmentIndex ? YES : NO];
}

- (void)updateUserDefaultAndTableItem:(NSString *)key toEnabled:(BOOL)isOn
{
    // save to disk.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[defaults arrayForKey:@"GeoItems"] mutableCopy];
    NSMutableDictionary *dict = [array[self.selectedRow] mutableCopy];
    dict[key] = isOn ? @YES : @NO;
    array[self.selectedRow] = dict;
    [defaults setObject:array forKey:@"GeoItems"];
    [defaults synchronize];
    // add new event.
#if !DEBUG
    [OBJCIPC sendMessageToSpringBoardWithMessageName:kGEUpdateEvents dictionary:nil replyHandler:nil];
#endif
    
    // save to memory.
    self.rootVC.geoFencingItems[self.selectedRow][key] = isOn ? @YES : @NO;
    if ([key isEqual:@"ExitedTrigger"]) {
        // update notify type.
        CLCircularRegion *region = self.rootVC.geoFencingItems[self.selectedRow][@"Location"];
        region.notifyOnExit = isOn;
        region.notifyOnEntry = !isOn;
        self.rootVC.geoFencingItems[self.selectedRow][@"Location"] = region;
        
        // re-registration the updated region.
        if (self.rootVC.isGeoFencingMonitoring && self.rootVC.geoFencingItems[self.selectedRow][@"Enabled"])
            [self.rootVC.locationManager startMonitoringForRegion:region];
    } else if ([key isEqualToString:@"Enabled"]) {
        // start ot stop geofencing.
        CLCircularRegion *region = self.rootVC.geoFencingItems[self.selectedRow][@"Location"];
        if (self.rootVC.isGeoFencingMonitoring) {
            if (isOn)
                [self.rootVC.locationManager startMonitoringForRegion:region];
            else
                [self.rootVC.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circle = [[MKCircleRenderer alloc] initWithCircle:overlay];
        //        circle.strokeColor = [UIColor blueColor];
        circle.fillColor = [UIColor blueColor];
        circle.alpha = 0.2;
        return circle;
    } else {
        return nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
