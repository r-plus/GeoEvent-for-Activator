%config(generator=internal)

#import <libactivator/libactivator.h>
#import <objcipc/objcipc.h>
#import "BulletinBoard.h"

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(int)feed;
@end

@interface GeoEventSubstrate : NSObject <LAEventDataSource>
@property (strong, nonatomic) NSArray *geoItems;
- (void)addGeoEvents;
- (void)updateEvents;
@end

static NSString * const kGEUpdateEvents = @"geoEventSubstrate_UpdateEvents";
static NSString * const kGEActivateEvent = @"geoEventSubstrate_ActivateEvent";
static NSString * const kPreferencePath = @"/var/mobile/Library/Preferences/jp.r-plus.geoevent.plist";
static NSString * const kEventPrefix = @"geoEvent4Activator";

@implementation GeoEventSubstrate
- (NSString *)triggerFromEventName:(NSString *)eventName
{
    for (NSDictionary *item in self.geoItems) {
        if ([[kEventPrefix stringByAppendingString:item[@"Identifier"]] isEqualToString:eventName]) {
            BOOL isExitedTrigger = [item[@"ExitedTrigger"] boolValue];
            return isExitedTrigger ? @"Leaving" : @"Arriving";
        }
    }
    return @"unknown";
}

// LAEventDataSource protocol requires
- (NSString *)localizedTitleForEventName:(NSString *)eventName
{
    for (NSDictionary *item in self.geoItems) {
        if ([[kEventPrefix stringByAppendingString:item[@"Identifier"]] isEqualToString:eventName]) {
            return item[@"Name"];
        }
    }
    return @"un-defined title";
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName
{
    return @"GeoEvent for Activator";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName
{
    return [@"GeoFencing event - " stringByAppendingString:[self triggerFromEventName:eventName]];
}

- (void)addGeoEvents
{
    NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:kPreferencePath];
    self.geoItems = pref[@"GeoItems"];
    for (NSDictionary *item in self.geoItems) {
        NSString *identifier = item[@"Identifier"];
        [LASharedActivator registerEventDataSource:self forEventName:[kEventPrefix stringByAppendingString:identifier]];
    }
    NSLog(@"added geo items = %@", self.geoItems);
}

- (void)updateEvents
{
    for (NSDictionary *item in self.geoItems) {
        NSString *identifier = item[@"Identifier"];
        NSString *eventName = [kEventPrefix stringByAppendingString:identifier ?: @""];
        NSLog(@"removed eventName = %@", eventName);
        [LASharedActivator unregisterEventDataSourceWithEventName:eventName];
    }
    NSLog(@"removed geo items = %@", self.geoItems);
    [self addGeoEvents];
}

+ (void)load
{
    @autoreleasepool {
        GeoEventSubstrate *geoEventSubstrate = [[self alloc] init];
        [geoEventSubstrate addGeoEvents];

        __weak GeoEventSubstrate *weakSelf = geoEventSubstrate;
        [OBJCIPC registerIncomingMessageFromAppHandlerForMessageName:kGEUpdateEvents handler:^NSDictionary *(NSDictionary *dict) {
            NSLog(@"catching kGEUpdateEvents");
            [weakSelf updateEvents];
            return nil;
        }];
    }
}

@end
