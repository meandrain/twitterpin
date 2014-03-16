//
//  CoreDataService.h
//  twitterpin
//
//  Created by Adrian Manolache on 15/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*
 Singleton service that allows interacting with a core data store allowing insert/delete/query of tweet locations
*/

@interface CoreDataService : NSObject
{
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id) sharedCoreDataService;

- (void)saveContext;

// insert new tweet location inside the core data database, this will also retain the current date
// for use in refreshing the database
- (void) insertTweetLocation: (CGPoint) location;

// perform a fetch on core data and delete all fetches older than lifetime
- (void) deleteTweetsOlderThan: (float) lifetime;

// retrieve all tweet locations objects as array
- (NSArray*) getTweetLocations;

@end
