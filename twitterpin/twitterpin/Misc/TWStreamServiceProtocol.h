//
//  TWStreamServiceProtocol.h
//  twitterpin
//

#import <Foundation/Foundation.h>

@protocol TWStreamServiceProtocol <NSObject>

- (void)tweetLocationFound: (id) point;

@end

