//
//  ViewController.m
//  twitterpin
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "CoreDataService.h"
#import "Constants.h"
#import "TweetLocation.h"

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
    
    self.cleanupTimer = [NSTimer scheduledTimerWithTimeInterval: LIFE_TIME_SECONDS
                                             target: self
                                           selector:@selector(tweetCleanup:)
                                           userInfo: nil repeats:YES];
}

- (void) stopTimer
{
    [self.cleanupTimer invalidate];
    self.cleanupTimer = nil;
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus netStatus = [curReach currentReachabilityStatus];

    if (netStatus == NotReachable)
    {
        // stop timer
        [self stopTimer];
    }
    else
    {
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
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
   
        MKPointAnnotation *toAdd = [[MKPointAnnotation alloc]init];
        CLLocationCoordinate2D locgeo = CLLocationCoordinate2DMake(point.x, point.y);
        toAdd.coordinate = locgeo;
        
        [strongSelf.mapView addAnnotation:toAdd];
    });
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
    [[CoreDataService sharedCoreDataService] deleteTweetsOlderThan: LIFE_TIME_SECONDS];
    
    [self updateUIMap];
}

- (void)updateUIMap
{
    NSArray* arr = [[CoreDataService sharedCoreDataService] getTweetLocations];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;

        [strongSelf.mapView removeAnnotations: strongSelf.mapView.annotations];
        
        for (int i=0; i<[arr count]; i++)
        {
            TweetLocation* tweetloc = [arr objectAtIndex: i];
            
            [strongSelf addPinAtLocation: CGPointMake([tweetloc.latitude doubleValue], [tweetloc.longitude doubleValue])];
        }
    });
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end