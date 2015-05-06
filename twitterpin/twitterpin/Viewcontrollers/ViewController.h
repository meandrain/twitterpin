//
//  ViewController.h
//  twitterpin
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Accounts/Accounts.h>
#import "TWStreamService.h"
#import "Reachability.h"

@interface ViewController : UIViewController<TWStreamServiceProtocol>
{
    TWStreamService* twStreamService;
}

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@end