//
//  TweetLocation.h
//  twitterpin
//
//  Created by Adrian Manolache on 15/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TweetLocation : NSManagedObject

@property (nonatomic, retain) NSDate* created_at;
@property (nonatomic, retain) NSNumber* latitude;
@property (nonatomic, retain) NSNumber* longitude;

@end
