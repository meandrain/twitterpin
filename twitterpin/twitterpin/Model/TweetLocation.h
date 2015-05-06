//
//  TweetLocation.h
//  twitterpin
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TweetLocation : NSManagedObject

@property (nonatomic, strong) NSDate* created_at;
@property (nonatomic, strong) NSNumber* latitude;
@property (nonatomic, strong) NSNumber* longitude;

@end
