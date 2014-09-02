//
//  ViewController.h
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/17.
//  Copyright (c) 2014年 hyde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *geoFencingItems;
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL isGeoFencingMonitoring;

- (void)addNewGeoFencingItem:(NSString *)name region:(CLCircularRegion *)region;

@end

extern NSString * const kGEUpdateEvents;
extern NSString * const kGEActivateEvent;

