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
@property (strong, nonatomic) NSArray *timeFilterCellItems;
@property (strong, nonatomic) NSIndexPath *datePickerIndexPath;
@property (strong, nonatomic) NSString *startFilterTime;
@property (strong, nonatomic) NSString *endFilterTime;

typedef enum GETimeFilterCellType : NSUInteger {
    GEEnabledCell = 0,
    GEStartCell,
    GEStartPickerCell,
    GEEndCell,
    GEEndPickerCell
} GETimeFilterCellType;

@end

static NSString * const kNameCellID = @"kNameCell";
static NSString * const kSwitchCellID = @"kSwitchCell";
static NSString * const kSegmentCellID = @"kSegmentCell";
static NSString * const kMapViewCellID = @"kMapViewCell";
static NSString * const kDateCellID = @"kDateCell";
static NSString * const kDatePickerCellID = @"kDatePickerCell";
static NSUInteger const kDatePickerTag = 99;

@implementation GeoFencingItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"GeoEvent";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.rootVC = ((UINavigationController *)self.parentViewController).viewControllers[0];
    NSLog(@"selected geo item = %@", self.rootVC.geoFencingItems[self.selectedRow]);
    self.isTimeFilterEnabled = [(NSNumber *)self.rootVC.geoFencingItems[self.selectedRow][@"TimeFilterEnabled"] boolValue];
    self.startFilterTime = self.rootVC.geoFencingItems[self.selectedRow][@"StartFilterTime"];
    self.endFilterTime = self.rootVC.geoFencingItems[self.selectedRow][@"EndFilterTime"];
    NSLog(@"start = %@", self.startFilterTime);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    [self updateTimeFilterCellItems];
}

- (NSString *)cellIdentifier:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    return kNameCellID;
                case 1:
                    return kSwitchCellID;
                case 2:
                    return kSegmentCellID;
            }
            break;
        }
        case 1: {
            NSUInteger cellType = [self.timeFilterCellItems[indexPath.row] intValue];
            switch (cellType) {
                case GEEnabledCell:
                    return kSwitchCellID;
                case GEStartCell:
                case GEEndCell:
                    return kDateCellID;
                case GEStartPickerCell:
                case GEEndPickerCell:
                    return kDatePickerCellID;
            }
            break;
        }
        case 2:
            return kMapViewCellID;
    }
    return @"cell";
}

- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifier:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if ([cellIdentifier isEqualToString:kDateCellID])
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        else
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    NSString *name = self.rootVC.geoFencingItems[self.selectedRow][@"Name"];
                    cell.textLabel.text = @"Name";
                    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width-120, 43)];
                    textField.text = name.length ? name : @"Name";
                    textField.delegate = self;
                    textField.textAlignment = NSTextAlignmentRight;
                    //textField.clipsToBounds = YES;
                    //textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    //textField.placeholder = @"placeholder";
                    cell.accessoryView = textField;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Enabled";
                    BOOL isEnabled = [(NSNumber *)self.rootVC.geoFencingItems[self.selectedRow][@"Enabled"] boolValue];
                    UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectZero];
                    sw.on = isEnabled;
                    [sw addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sw;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 1: {
            NSUInteger cellType = [self.timeFilterCellItems[indexPath.row] intValue];
            switch (cellType) {
                case GEEnabledCell: {
                    cell.textLabel.text = @"Time Filter";
                    UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectZero];
                    sw.on = self.isTimeFilterEnabled;
                    [sw addTarget:self action:@selector(changeTimeFilterSwitch:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sw;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case GEStartCell: {
                    cell.textLabel.text = @"Start Time";
                    cell.detailTextLabel.text = self.startFilterTime;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case GEEndCell: {
                    cell.textLabel.text = @"End Time";
                    cell.detailTextLabel.text = self.endFilterTime;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    break;
                }
                case GEStartPickerCell:
                case GEEndPickerCell: {
                    UIDatePicker *checkDatePicker = (UIDatePicker *)[cell viewWithTag:kDatePickerTag];
                    if (!checkDatePicker) {
                        UIDatePicker *datePicker = [UIDatePicker new];
                        datePicker.datePickerMode = UIDatePickerModeTime;
                        datePicker.minuteInterval = 5;
                        datePicker.tag = kDatePickerTag;
                        [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
                        NSString *dateString = (cellType == GEStartPickerCell) ? self.startFilterTime : self.endFilterTime;
                        NSDateFormatter *formatter = [NSDateFormatter new];
                        [formatter setLocale:[NSLocale systemLocale]];
                        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
                        [formatter setDateFormat:@"HH:mm"];
                        NSDate *date = [formatter dateFromString:dateString];
                        datePicker.date = date;
                        [cell.contentView addSubview:datePicker];
                    }
                    break;
                }
            }
            break;
        }
        case 2: {
            MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
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
            
            [cell.contentView addSubview:mapView];
            
            UIControl *control = [[UIControl alloc] initWithFrame:mapView.bounds];
            [control addTarget:self action:@selector(locationTapped:) forControlEvents:UIControlEventTouchUpInside];
            [mapView addSubview:control];
            break;
        }
            
    }
    
    return cell;
}

- (void)dateChanged:(UIDatePicker *)picker
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row-1 inSection:self.datePickerIndexPath.section];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"HH:mm"];
    NSString *changedTimeString = [formatter stringFromDate:picker.date];
    cell.detailTextLabel.text = changedTimeString;
    if ([cell.textLabel.text hasPrefix:@"Start"]) {
        self.startFilterTime = changedTimeString;
        NSLog(@"dateChanged, start = %@", self.startFilterTime);
        [self saveFilterTime:changedTimeString key:@"StartFilterTime"];
    } else {
        self.endFilterTime = changedTimeString;
        [self saveFilterTime:changedTimeString key:@"EndFilterTime"];
    }
}

- (void)saveFilterTime:(NSString *)timeString key:(NSString *)key
{
    self.rootVC.geoFencingItems[self.selectedRow][key] = timeString;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[defaults arrayForKey:@"GeoItems"] mutableCopy];
    NSMutableDictionary *dict = [array[self.selectedRow] mutableCopy];
    dict[key] = timeString;
    array[self.selectedRow] = dict;
    [defaults setObject:array forKey:@"GeoItems"];
    [defaults synchronize];
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

- (UIDatePicker *)showingDatePicker
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
    NSLog(@"cell = %@", cell);
    return (UIDatePicker *)[cell viewWithTag:kDatePickerTag];
}

- (void)showDatePickerCellForIndexPath:(NSIndexPath *)indexPath
{
    BOOL showingStartTimePicker = NO;
    if ([self hasInlineDatePicker]) {
        showingStartTimePicker = (self.datePickerIndexPath.row < indexPath.row);
    }
    BOOL sameCellClicked = (self.datePickerIndexPath.row == indexPath.row);
    
    [self.tableView beginUpdates];
    NSIndexPath *adjustedIndexPath = indexPath;
    if ([self hasInlineDatePicker]) {
        [self.tableView deleteRowsAtIndexPaths:@[self.datePickerIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
        if (showingStartTimePicker) {
            adjustedIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:1];
        }
    }
    
    if (!sameCellClicked) {
        NSLog(@"not same cell clicking...");
        [self.tableView insertRowsAtIndexPaths:@[adjustedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.datePickerIndexPath = adjustedIndexPath;
    }
    [self updateTimeFilterCellItems];
    [self.tableView endUpdates];
    
    // update picker date.
    if ([self hasInlineDatePicker]) {
        NSString *dateString = adjustedIndexPath.row == 2 ? self.startFilterTime : self.endFilterTime;
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setLocale:[NSLocale systemLocale]];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"HH:mm"];
        NSLog(@"Picker = %@", [self showingDatePicker]);
        [[self showingDatePicker] setDate:[formatter dateFromString:dateString] animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 1)
        return;
    
    NSUInteger cellType = [self.timeFilterCellItems[indexPath.row] intValue];
    switch (cellType) {
        case GEStartCell:
        case GEEndCell: {
            [self updateTimeFilterCellItems];
            NSIndexPath *startPickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:1];
            [self showDatePickerCellForIndexPath:startPickerIndexPath];
            break;
        }
        default:
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
        case 1:
            NSLog(@"count = %ld", (unsigned long)self.timeFilterCellItems.count);
            return self.timeFilterCellItems.count;
        case 2:
            return 1;
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 2 ? @"Location" : @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            return 44.0;
        case 1: {
            NSUInteger cellType = [self.timeFilterCellItems[indexPath.row] intValue];
            switch (cellType) {
                case GEEnabledCell:
                case GEStartCell:
                case GEEndCell:
                    return 44.0;
                case GEStartPickerCell:
                case GEEndPickerCell:
                    return 200.0;
            }
        }
        case 2:
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

- (void)updateTimeFilterCellItems
{
    if (self.isTimeFilterEnabled) {
        if (![self hasInlineDatePicker]) {
            self.timeFilterCellItems = @[@(GEEnabledCell), @(GEStartCell), @(GEEndCell)];
        } else {
            if (self.datePickerIndexPath.row == 2) {
                self.timeFilterCellItems = @[@(GEEnabledCell), @(GEStartCell), @(GEStartPickerCell), @(GEEndCell)];
            } else {
                self.timeFilterCellItems = @[@(GEEnabledCell), @(GEStartCell), @(GEEndCell), @(GEEndPickerCell)];
            }
        }
    } else {
        self.timeFilterCellItems = @[@(GEEnabledCell)];
    }
}

- (void)changeTimeFilterSwitch:(UISwitch *)sender
{
    NSLog(@"timer filter");
    self.isTimeFilterEnabled = sender.isOn;
    [self updateUserDefaultAndTableItem:@"TimeFilterEnabled" toEnabled:sender.isOn];
    [self updateTimeFilterCellItems];
    NSIndexPath *startIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    NSIndexPath *endIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    NSArray *closeIndexPaths;
    if ([self hasInlineDatePicker] && !sender.isOn) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:3 inSection:1];
        closeIndexPaths = @[startIndexPath, endIndexPath, lastIndexPath];
        self.datePickerIndexPath = nil;
    } else {
        closeIndexPaths = @[startIndexPath, endIndexPath];
    }

    if (sender.isOn) {
        [self.tableView insertRowsAtIndexPaths:closeIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:closeIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
