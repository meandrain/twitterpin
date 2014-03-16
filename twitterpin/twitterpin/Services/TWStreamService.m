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
        // Allocate an account store to query twitter accounts from
        self.accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

// main entry point
- (void) startWithDelegate: (id<TWStreamServiceProtocol>) del andKeyWord: (NSString*) seKey
{
    // store delegates and search key
    delegate = del;
    self.searchKey = seKey;
    
    // make the connection with the twitter account and open the streaming connection
    [self accessTwitterAccountWithAccountStore];
}

- (void)accessTwitterAccountWithAccountStore
{
    // grab an account identifier for twitter accounts, we don't need facebook or others
    ACAccountType *twitterAccountType = [self.accountStore
                                         accountTypeWithAccountTypeIdentifier:
                                         ACAccountTypeIdentifierTwitter];
    
    // request access from a twitter account in background
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:nil completion:^(BOOL granted, NSError *error)
         {
             // if the user grants access try to grab an account
             if (granted)
             {
                 NSArray *twitterAccounts = [self.accountStore
                                             accountsWithAccountType:twitterAccountType];
                
                 // if no accounts are registered on the device fail with error
                 if (twitterAccounts.count == 0)
                 {
                    [self showTwitterError: @"Please make sure you have a Twitter account set up in Settings."];
                 }
                 else
                 {
                     // retrieve the identifier of the last account used
                     NSString *twitterAccountIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:AccountTwitterSelectedIdentifier];
                     
                     self.account = [self.accountStore accountWithIdentifier:twitterAccountIdentifier];
                     
                     // if there was an account selected in the past go ahead and start streaming
                     if (self.account)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{

                             [self startStreaming];
                         });
                     }
                     else
                     {
                         // if we get here either there was no identifier stored or it became invalid in the meantime
                         // remove if and grab another one
                         [[NSUserDefaults standardUserDefaults] removeObjectForKey:AccountTwitterSelectedIdentifier];
                         [[NSUserDefaults standardUserDefaults] synchronize];
                         
                         // if there are multiple accounts ask the user which to use
                         if (twitterAccounts.count > 1)
                         {
                             // use an alert view to select the account
                             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select an account"
                                                                                 message:@"Please choose one of your Twitter accounts"
                                                                                delegate:self
                                                                       cancelButtonTitle:@"Cancel"
                                                                       otherButtonTitles:nil];
                             
                             // make on button for every account
                             for (ACAccount *account in twitterAccounts)
                             {
                                 [alertView addButtonWithTitle:account.accountDescription];
                             }
                             
                             // finally display UI on the main thread
                             dispatch_async(
                                            dispatch_get_main_queue(), ^{
                                                [alertView show];
                                            });
                         }
                         else
                         {  
                             // otherwise grab the only one and start streaming
                             self.account = [twitterAccounts lastObject];
                             dispatch_async(
                                            dispatch_get_main_queue(), ^{
                                                [self startStreaming];
                                            });
                         }
                     }
                 }
             }
             else
             {
                 // Access was not granted, is this becuase of an error ?
                 if (error)
                 {
                     // if so tell the user about this
                     [self showTwitterError: @"Please make sure you have a Twitter account set up in Settings. Also grant access to this app"];
                 }
                 else
                 {
                     // this means restricted access so redirect him to settings
                     [self showTwitterError: @"We can't access Twitter, please add an account in the Settings app"];
                 }
             }
         }];
    });
}

// open an async NSURLConnection and wait for updates
- (void) startStreaming
{
    // use a search key to filter all the tweets
    [self startStreamingWithKeyword: self.searchKey];
}

- (void)startStreamingWithKeyword:(NSString *)aKeyword
{
    // open an active connection to the twitter stream endpoint
    NSURL *url = [NSURL URLWithString: @"https://stream.twitter.com/1.1/statuses/filter.json"];
    
    // track tweets that use aKeyword
    NSDictionary *params = @{@"track" : aKeyword};

    // use a social request object to make a post request
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    // set the account we just grabbed above
    [request setAccount:self.account];
    
    // dispatch the connection on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURLConnection *aConn = [NSURLConnection connectionWithRequest:[request preparedURLRequest] delegate:self];
        [aConn start];
    });
}

// method to process a given json string representing a tweet
- (void) processTweet: (NSString*) str
{
    // use the standard serialization provided by the os
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
        // if no error occurs grab the coordinates
        NSDictionary* coordinates = [responseJSON objectForKey: @"coordinates"];
        if (coordinates)
        {
            if ([coordinates isKindOfClass: [NSDictionary class]] == YES) // valid coordinates
            {
                // if gps coordinates are available perform a selector on the delegate to notify that we found
                // a new tweet with valid coordinates
                
                [delegate performSelector: @selector(tweetLocationFound:) withObject: [coordinates valueForKey: @"coordinates"]];
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // addition, take care of error here
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // we received data from the twitter stream endpoint, each tweet is separanted by a a carriage return and a line feed characters, test for both because \n can be present inside the tweet json

    // do work in separate thread
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        // convert data to ascii encoding
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        // separate it into tweets
        NSArray* components = [dataString componentsSeparatedByString: @"\r\n"];
        
        // the last component is not a valid tweet, iterate through the container and call the utility function on each
        for (int i=0; i<components.count - 1; i++)
        {
            [self processTweet: [components objectAtIndex: i] ];
        }
        
    });
}

// alert view function to select between multiple twitter accounts
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{   
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        // grab the account selected
        ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        NSArray *twitterAccounts = [self.accountStore
                                    accountsWithAccountType:twitterAccountType];
        
        self.account = twitterAccounts[(buttonIndex - 1)];
    
        // store it's identifier locally for next use
        [[NSUserDefaults standardUserDefaults] setObject:self.account.identifier forKey:AccountTwitterSelectedIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // and start the streaming process
        [self startStreaming];
    }
}

// utility error function
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