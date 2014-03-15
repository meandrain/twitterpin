//
//  ViewController.h
//  twitterpin
//
//  Created by Adrian Manolache on 14/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
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

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end