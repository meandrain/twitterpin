//
//  TWStreamService.m
//  twitterpin
//
//  Created by Adrian Manolache on 15/03/14.
//  Copyright (c) 2014 Adrian Manolache. All rights reserved.
//

#import "TWStreamService.h"
#import "AppDelegate.h"
#import <Social/Social.h>

@interface TWStreamService ()

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (nonatomic, strong) ACAccount* account;
@property (nonatomic, strong) NSString* searchKey;

@end

@implementation TWStreamService

- (id) init
{
    if (self = [super init])
    {   
        self.accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void) startWithDelegate: (id<TWStreamServiceProtocol>) del andKeyWord: (NSString*) seKey
{
    delegate = del;
    self.searchKey = seKey;
    
    [self accessTwitterAccountWithAccountStore];
}

- (void)accessTwitterAccountWithAccountStore
{
    ACAccountType *twitterAccountType = [self.accountStore
                                         accountTypeWithAccountTypeIdentifier:
                                         ACAccountTypeIdentifierTwitter];
    
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:nil completion:^(BOOL granted, NSError *error)
         {
             if (granted)
             {
                 NSArray *twitterAccounts = [self.accountStore
                                             accountsWithAccountType:twitterAccountType];
                 
                 if (twitterAccounts.count == 0)
                 {
                    [self showTwitterError: @"Please make sure you have a Twitter account set up in Settings."];
                 }
                 else
                 {
                     NSString *twitterAccountIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:AccountTwitterSelectedIdentifier];
                     
                     self.account = [self.accountStore accountWithIdentifier:twitterAccountIdentifier];
                     
                     if (self.account)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{

                             [self accessGranted];
                         });
                     }
                     else
                     {
                         [[NSUserDefaults standardUserDefaults] removeObjectForKey:AccountTwitterSelectedIdentifier];
                         
                         [[NSUserDefaults standardUserDefaults] synchronize];
                         
                         if (twitterAccounts.count > 1)
                         {
                             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select an account"
                                                                                 message:@"Please choose one of your Twitter accounts"
                                                                                delegate:self
                                                                       cancelButtonTitle:@"Cancel"
                                                                       otherButtonTitles:nil];
                             
                             for (ACAccount *account in twitterAccounts)
                             {
                                 [alertView addButtonWithTitle:account.accountDescription];
                             }
                             
                             dispatch_async(
                                            dispatch_get_main_queue(), ^{
                                                [alertView show];
                                            });
                         }
                         else
                         {
                             self.account = [twitterAccounts lastObject];
                            
                             dispatch_async(
                                            dispatch_get_main_queue(), ^{
                                                [self accessGranted];
                                            });
                         }
                     }
                 }
             }
             else
             {
                 if (error)
                 {
                     [self showTwitterError: @"Please make sure you have a Twitter account set up in Settings. Also grant access to this app"];
                 }
                 else
                 {
                     [self showTwitterError: @"We can't access Twitter, please add an account in the Settings app"];
                 }
             }
         }];
    });
}

- (void) accessGranted
{
    [self startStreamingWithKeyword: self.searchKey];
}

- (void)startStreamingWithKeyword:(NSString *)aKeyword
{
    NSURL *url = [NSURL URLWithString: @"https://stream.twitter.com/1.1/statuses/filter.json"];
    NSDictionary *params = @{@"track" : aKeyword};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    [request setAccount:self.account];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURLConnection *aConn = [NSURLConnection connectionWithRequest:[request preparedURLRequest] delegate:self];
        [aConn start];
    });
}

- (void) processTweet: (NSString*) str
{
    NSError* error = nil;
    NSDictionary *responseJSON = [NSJSONSerialization
                                  JSONObjectWithData: [str dataUsingEncoding: NSUTF8StringEncoding]
                                  options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
                                  error: &error];
    if (error != nil)
    {
    }
    else
    {
        NSDictionary* coordinates = [responseJSON objectForKey: @"coordinates"];
        if (coordinates)
        {
            if ([coordinates isKindOfClass: [NSDictionary class]] == YES) // valid coordinates
            {   
                [delegate performSelector: @selector(tweetLocationFound:) withObject: [coordinates valueForKey: @"coordinates"]];
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{   
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSArray* components = [dataString componentsSeparatedByString: @"\r\n"];

    for (int i=0; i<components.count - 1; i++)
    {
        [self processTweet: [components objectAtIndex: i] ];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{   
    if (buttonIndex != alertView.cancelButtonIndex) {
    
        ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        NSArray *twitterAccounts = [self.accountStore
                                    accountsWithAccountType:twitterAccountType];
        
        self.account = twitterAccounts[(buttonIndex - 1)];
    
        [[NSUserDefaults standardUserDefaults] setObject:self.account.identifier forKey:AccountTwitterSelectedIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self accessGranted];
    }
}

- (void) showTwitterError: (NSString*) message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Twitter Error"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dimiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

@end