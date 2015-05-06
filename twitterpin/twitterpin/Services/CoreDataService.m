//
//  CoreDataService.m
//  twitterpin
//

#import "CoreDataService.h"
#import "TweetLocation.h"

@implementation CoreDataService
{
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id) sharedCoreDataService {
    static CoreDataService *coreDataService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coreDataService = [[self alloc] init];
    });
                  
    return coreDataService;
}

- (void)saveContext
{
    // don't save objects on disk this is no neededed, on the occasion that this will
    // be needed just decomment the above code
    
    /*
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    [managedObjectContext lock];
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    [managedObjectContext unlock];
    */
}
    
- (void) insertTweetLocation: (CGPoint) location
{
    // insert a new tweet location object and populate it with a locatino and current date
    TweetLocation* newTweetLocation = [NSEntityDescription insertNewObjectForEntityForName:@"TweetLocation" inManagedObjectContext:self.managedObjectContext];
    
    newTweetLocation.latitude = [NSNumber numberWithDouble: location.x];
    newTweetLocation.longitude = [NSNumber numberWithDouble: location.y];
    newTweetLocation.created_at = [NSDate date];
    
    // save changes to disk
    [self saveContext];
}

- (NSArray*) getTweetLocations
{
    // grab all tweet location objects from the store
    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TweetLocation" inManagedObjectContext:context];
    
    [request setEntity: entity];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error: &error];

    if (error != nil) {
        return nil;
    }
    
    return results;
}

- (void) deleteTweetsOlderThan: (float) lifetime
{
    // perform a fetch request and retrieve all tweets than need to be erased, use a date comparison predicate
    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TweetLocation" inManagedObjectContext:context];
    
    [request setEntity: entity];
    
    [request setPredicate: [NSPredicate predicateWithFormat:@"created_at < %@", [[NSDate date] dateByAddingTimeInterval: -lifetime]]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error: &error];
    
    // iterate through each of the and delete
    for (int i=0; i<results.count; i++)
    {
        NSManagedObject* obj = [results objectAtIndex: i];
        [self.managedObjectContext deleteObject: obj];
    }
    
    // persist modifications
    [self saveContext];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }   
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"asdsa.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
