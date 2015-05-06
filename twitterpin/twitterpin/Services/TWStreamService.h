//
//  TWStreamService.h
//  twitterpin
//

#define AccountTwitterAccessGranted @"TwitterAccessGranted"
#define AccountTwitterSelectedIdentifier @"TwitterAccountSelectedIdentifier"

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

#import "TWStreamServiceProtocol.h"

@interface TWStreamService : NSObject
{
    id<TWStreamServiceProtocol> delegate;
}
    
- (void) startWithDelegate: (id<TWStreamServiceProtocol>) del andKeyWord: (NSString*) searchKey;

@end