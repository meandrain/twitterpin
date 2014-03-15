//
//  TWStreamServiceProtocol.h
//  twitterpin
//
//  Created by Adrian Manolache on 15/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TWStreamServiceProtocol <NSObject>

- (void)tweetLocationFound: (id) point;

@end

