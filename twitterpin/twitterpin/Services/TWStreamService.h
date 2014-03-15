//
//  TWStreamService.h
//  twitterpin
//
//  Created by Adrian Manolache on 15/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
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