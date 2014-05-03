objectiveflickr
===============

ObjectiveFlickr, a Flickr API framework for Objective-C.

Dependencies
------------

AFNetworking version 2.2.3 is required, you will find it here: https://github.com/AFNetworking/AFNetworking/tree/2.2.3

Getting Started
---------------

In `YourApp-Info.plist`, make sure sure you have setup the url scheme like that:
```xml
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string></string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>your_scheme</string>
    </array>
  </dict>
</array>
```

Then in `YourAppDelegate.m` you can do something like that:
```objc
#import "ObjectiveFlickr.h"

NSString * const kFlickrAPIKey = @"your_api_key";
NSString * const kFlickrSecret = @"your_secret_key";
NSString * const kFlickrCallbackURL = @"your_scheme://auth";

NSString * const kFlickrUserDefaultsOAuthTokenKey = @"flickr-user-defaults-token-key";
NSString * const kFlickrUserDefaultsOAuthTokenSecretKey = @"flickr-user-defaults-token-secret-key";

@implementation YourAppDelegate
{
    ObjectiveFlickr *_flickr;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];

    _flickr = [[ObjectiveFlickr alloc] initWithAPIKey:kFlickrAPIKey sharedSecret:kFlickrSecret];
    _flickr.oauthToken = [[NSUserDefaults standardUserDefaults] objectForKey:kFlickrUserDefaultsOAuthTokenKey];
    _flickr.oauthTokenSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kFlickrUserDefaultsOAuthTokenSecretKey];
    
    if (_flickr.oauthToken.length > 0 && _flickr.oauthTokenSecret.length > 0) {
        [_flickr fetchRequestTokenWithCallbackURL:[NSURL URLWithString:kFlickrCallbackURL] success:^(NSString *requestToken) {
            NSURL *userAuthorizationURL = [_flickr userAuthorizationURLWithRequestToken:requestToken requestedPermission:OFFlickrReadPermission];
            [[UIApplication sharedApplication] openURL:userAuthorizationURL];
        } failure:^(NSInteger statusCode, NSError *error) {
            // let the user know it failed
        }];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSDictionary *values = OFExtractURLQueryParameter(url.query);
    NSString *oauthToken = values[@"oauth_token"];
    NSString *oauthVerifier = values[@"oauth_verifier"];
    if (oauthToken.length && oauthVerifier.length) {
        [_flickr fetchAccessTokenWithRequestToken:oauthToken verifier:oauthVerifier success:^{
            [[NSUserDefaults standardUserDefaults] setObject:_flickr.oauthToken forKey:kFlickrUserDefaultsOAuthTokenKey];
            [[NSUserDefaults standardUserDefaults] setObject:_flickr.oauthTokenSecret forKey:kFlickrUserDefaultsOAuthTokenSecretKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // cool, now you can get started, for example we'll use the photo search
            
            [_flickr sendWithMethod:@"GET"
                               path:@"flickr.photos.search"
                          arguments:@{@"user_id": _flickr.userId}
                            success:^(NSDictionary *responseDictionary) {
                                // do something
                            }
                            failure:^(NSInteger statusCode, NSError *error) {
                                // do something else
                            }];
            
            
        } failure:^(NSInteger statusCode, NSError *error) {
            // let the user know it failed
        }];
        return YES;
    }

    return NO;
}
```

Uploading images
----------------

Once the user is authenticated with Flickr the app can upload images by calling uploadImage or uploadImageFromUrl.
uploadImage will upload an image from the users device, while uploadImageFromUrl will upload an image from the specified URL.
In this case the file is first downloaded on the device.

Here an example for uploadImage:

```objc
// test.jpg needs to be in the bundle
NSString* filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];

[_flickr uploadImage:filePath
           arguments:@{@"description": @"some description"}
             success:^(NSDictionary *responseDictionary) {
                 NSLog(@"response %@", responseDictionary);
             }
             failure:^(NSInteger statusCode, NSError *error) {
                 // do something else
                 NSLog(@"error: %@", error);
             }];

```

and for uploadImageFromUrl:

```objc
[_flickr uploadImageFromUrl:@"http://1.bp.blogspot.com/-6jAXe8SUPPY/T-T2wiyQYRI/AAAAAAAAAV8/ckQc_qsanL4/s1600/03-turing-miscellany-09.jpg"
                 arguments:@{@"description": @"some description"}
                   success:^(NSDictionary *responseDictionary) {
                       NSLog(@"response %@", responseDictionary);
                   }
                   failure:^(NSInteger statusCode, NSError *error) {
                       // do something else
                       NSLog(@"error: %@", error);
                   }];
```
