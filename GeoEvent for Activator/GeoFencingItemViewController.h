//
//  GeoFencingItemViewController.h
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/17.
//  Copyright (c) 2014年 hyde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ViewController.h"

@interface GeoFencingItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) NSUInteger selectedRow;
@property (assign, nonatomic) BOOL isTimeFilterEnabled;
@property (weak, nonatomic) ViewController *rootVC;

@end
