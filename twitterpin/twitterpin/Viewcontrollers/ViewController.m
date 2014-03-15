//
//  ViewController.m
//  twitterpin
//
//  Created by Adrian Manolache on 14/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "CoreDataService.h"
#import "Constants.h"
#import "TweetLocation.h"

@interface DeletableMapAnnotation : MKPointAnnotation {
}

@property(nonatomic, strong) NSDate* created_at;

@end

@implementation DeletableMapAnnotation

@end

@interface ViewController ()
{
    Reachability* hostReachibility;
}

@property (nonatomic, strong) NSTimer* cleanupTimer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    hostReachibility = [Reachability reachabilityForInternetConnection];
	[hostReachibility startNotifier];
    
    [self startStreamService];
    [self spawnCleanupTimer];
}

- (void) startStreamService
{
    twStreamService = [[TWStreamService alloc] init];
    [twStreamService startWithDelegate: self andKeyWord: @"me"];
}

- (void) spawnCleanupTimer
{
    // stop the timer if it's running
    [self stopTimer];
    
    // NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.cleanupTimer = [NSTimer scheduledTimerWithTimeInterval: LIFE_TIME_SECONDS
                                             target: self
                                           selector:@selector(tweetCleanup:)
                                           userInfo: nil repeats:YES];
    
    // NSLog(@"timer=%d", (int)self.cleanupTimer);
}

- (void) stopTimer
{
    // NSLog(@"stopTimer=%d", (int)self.cleanupTimer);
    
    [self.cleanupTimer invalidate];
    self.cleanupTimer = nil;
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus netStatus = [curReach currentReachabilityStatus];

    if (netStatus == NotReachable)
    {   
        NSLog(@"Network is offline");
        
        // stop timer
        [self stopTimer];
    }
    else
    {
        NSLog(@"Network is back online");
        
        // network is back online, reset everything
        [self tweetCleanup: nil];
        [self startStreamService];
        [self spawnCleanupTimer];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) addPinAtLocation: (CGPoint) point
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    DeletableMapAnnotation *toAdd = [[DeletableMapAnnotation alloc]init];
    CLLocationCoordinate2D locgeo = CLLocationCoordinate2DMake(point.x, point.y);
    toAdd.coordinate = locgeo;
    toAdd.created_at = [NSDate date];
    
    [self.mapView addAnnotation:toAdd];
}

- (void) tweetLocationFound:(id) pointDict
{
    NSArray* array = (NSArray*) pointDict;
    
    CGPoint point = CGPointMake([[array objectAtIndex: 1] floatValue], [[array objectAtIndex: 0] floatValue]);
    
    // also add it in core data
    [[CoreDataService sharedCoreDataService] insertTweetLocation: point];
    
    // add it on the map
    [self addPinAtLocation: point];
}

- (void) tweetCleanup: (NSTimer*) timer
{
    NSLog(@"%s %0.2f",__PRETTY_FUNCTION__, CACurrentMediaTime());

    [[CoreDataService sharedCoreDataService] deleteTweetsOlderThan: LIFE_TIME_SECONDS];
    
    [self updateUIMap];
}

- (void)updateUIMap
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.mapView removeAnnotations: self.mapView.annotations];
    
    NSArray* arr = [[CoreDataService sharedCoreDataService] getTweetLocations];
    
    for (int i=0; i<[arr count]; i++)
    {
        TweetLocation* tweetloc = [arr objectAtIndex: i];
        
        [self addPinAtLocation: CGPointMake([tweetloc.latitude doubleValue], [tweetloc.longitude doubleValue])];
    }
    
    /*
    NSArray* annotations = [self.mapView annotations];
    NSDate* cleanupDate = [[NSDate date] dateByAddingTimeInterval: -LIFE_TIME_SECONDS];

    NSMutableArray* annotationsToRemove = [[NSMutableArray alloc] init];
    
    for (int i=0; i<annotations.count; i++)
    {
        DeletableMapAnnotation* deletableAnnotation = (DeletableMapAnnotation*)[annotations objectAtIndex: i];
        
        if ([deletableAnnotation.created_at compare: cleanupDate] == NSOrderedDescending)
        {
            // this annotation must be deleted
            [annotationsToRemove addObject: deletableAnnotation];
        }
    }
    
    [self.mapView removeAnnotations: annotationsToRemove];
    
    NSLog(@"Removed %d annotations annotations.count=%d", annotationsToRemove.count, annotations.count);
    */
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end