//
// ObjectiveFlickr.m
//
// Copyright (c) 2006-2014 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "ObjectiveFlickr.h"
#import "OFUtilities.h"
#import "AFHTTPRequestOperationManager.h"

// permisions
NSString *const OFFlickrReadPermission = @"read";
NSString *const OFFlickrWritePermission = @"write";
NSString *const OFFlickrDeletePermission = @"delete";

// urls
static NSString *const kFlickrURLOAuth = @"https://www.flickr.com/services/oauth/";
static NSString *const kFlickrURLAPI = @"https://api.flickr.com/services/rest/";

// utils
static NSString *const kEscapeChars = @"`~!@#$^&*()=+[]\\{}|;':\",/<>?";

@interface ObjectiveFlickr ()
- (NSURL *)_oauthURLFromBaseURL:(NSURL *)url method:(NSString *)method arguments:(NSDictionary *)arguments;
- (NSDictionary *)_signedOAuthHTTPQueryArguments:(NSDictionary *)arguments baseURL:(NSURL *)url method:(NSString *)method;
@end

@implementation ObjectiveFlickr
{
    NSOperationQueue *_operationQueue;
}

#pragma mark Public methods

- (id)initWithAPIKey:(NSString *)apiKey sharedSecret:(NSString *)sharedSecret
{
    if ((self = [super init])) {
        _key = [apiKey copy];
        _sharedSecret = [sharedSecret copy];
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (NSURL *)userAuthorizationURLWithRequestToken:(NSString *)requestToken
                            requestedPermission:(NSString *)permission
{
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@%@", kFlickrURLOAuth, @"authorize"];
    [urlString appendFormat:@"?%@=%@", @"oauth_token", requestToken];
    if (permission.length > 0) {
        [urlString appendFormat:@"&%@=%@", @"perms", permission];
    }
    return [NSURL URLWithString:urlString];
}

- (void)fetchRequestTokenWithCallbackURL:(NSURL *)callbackURL
                                 success:(void (^)(NSString *requestToken))success
                                 failure:(void (^)(NSInteger statusCode, NSError *error))failure
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kFlickrURLOAuth, @"request_token"];
    NSURL *requestURL = [self _oauthURLFromBaseURL:[NSURL URLWithString:urlString]
                                            method:@"GET"
                                         arguments:@{@"oauth_callback": [callbackURL absoluteString]}];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:requestURL]];
    requestOperation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSDictionary *responseDictionary = OFExtractURLQueryParameter(responseString);
            _oauthToken = responseDictionary[@"oauth_token"];
            _oauthTokenSecret = responseDictionary[@"oauth_token_secret"];
            success(_oauthToken);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.response.statusCode, error);
        }
    }];
    [_operationQueue addOperation:requestOperation];
}

- (void)fetchAccessTokenWithRequestToken:(NSString *)requestToken
                                verifier:(NSString *)verifier
                                 success:(void (^)())success
                                 failure:(void (^)(NSInteger statusCode, NSError *error))failure
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kFlickrURLOAuth, @"access_token"];
    NSURL *requestURL = [self _oauthURLFromBaseURL:[NSURL URLWithString:urlString]
                                            method:@"GET"
                                         arguments:@{@"oauth_token": requestToken, @"oauth_verifier": verifier}];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:requestURL]];
    requestOperation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSDictionary *responseDictionary = OFExtractURLQueryParameter(responseString);
            _oauthToken = responseDictionary[@"oauth_token"];
            _oauthTokenSecret = responseDictionary[@"oauth_token_secret"];
            _username = [responseDictionary[@"username"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            _fullname = [responseDictionary[@"fullname"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            _userId = [responseDictionary[@"user_nsid"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.response.statusCode, error);
        }
    }];
    [_operationQueue addOperation:requestOperation];
}

- (void)sendWithMethod:(NSString *)method
                  path:(NSString *)path
             arguments:(NSDictionary *)arguments
               success:(void (^)(NSDictionary *responseDictionary))success
               failure:(void (^)(NSInteger statusCode, NSError *error))failure
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:path forKey:@"method"];
    [parameters setObject:@"json" forKey:@"format"];
    [parameters setObject:@"1" forKey:@"nojsoncallback"];
    
    if (arguments) {
        [parameters addEntriesFromDictionary:arguments];
    }
    
    NSURL *requestURL = [self _oauthURLFromBaseURL:[NSURL URLWithString:kFlickrURLAPI]
                                            method:method
                                         arguments:parameters];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:requestURL]];
    requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success((NSDictionary *)responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.response.statusCode, error);
        }
    }];
    [_operationQueue addOperation:requestOperation];
}

#pragma mark Private methods

- (NSURL *)_oauthURLFromBaseURL:(NSURL *)url method:(NSString *)method arguments:(NSDictionary *)arguments
{
    NSDictionary *newArgs = [self _signedOAuthHTTPQueryArguments:arguments baseURL:url method:method];
    
    NSMutableArray *queryArray = [NSMutableArray array];
    NSEnumerator *kenum = [newArgs keyEnumerator];
    NSString *k;
    while ((k = [kenum nextObject]) != nil) {
        [queryArray addObject:[NSString stringWithFormat:@"%@=%@", k, OFEscapedURLStringFromNSStringWithExtraEscapedChars([[newArgs objectForKey:k] description], kEscapeChars)]];
    }
    
    NSString *newURLStringWithQuery = [NSString stringWithFormat:@"%@?%@", [url absoluteString], [queryArray componentsJoinedByString:@"&"]];
    return [NSURL URLWithString:newURLStringWithQuery];
}

- (NSDictionary *)_signedOAuthHTTPQueryArguments:(NSDictionary *)arguments baseURL:(NSURL *)url method:(NSString *)method
{
    NSMutableDictionary *newArgs = [NSMutableDictionary dictionaryWithDictionary:arguments];
    [newArgs setObject:[OFGenerateUUIDString() substringToIndex:8] forKey:@"oauth_nonce"];
    [newArgs setObject:[NSString stringWithFormat:@"%lu", (long)[[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [newArgs setObject:@"1.0" forKey:@"oauth_version"];
    [newArgs setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [newArgs setObject:_key forKey:@"oauth_consumer_key"];
    
    if (![arguments objectForKey:@"oauth_token"] && _oauthToken) {
        [newArgs setObject:_oauthToken forKey:@"oauth_token"];
    }
    
    NSString *signatureKey = [NSString stringWithFormat:@"%@&%@", _sharedSecret, _oauthTokenSecret ? _oauthTokenSecret : @""];
    
    NSMutableString *baseString = [NSMutableString string];
    [baseString appendString:method];
    [baseString appendString:@"&"];
    [baseString appendString:OFEscapedURLStringFromNSStringWithExtraEscapedChars([url absoluteString], kEscapeChars)];
    
    NSArray *sortedArgKeys = [[newArgs allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [baseString appendString:@"&"];
    
    NSMutableArray *baseStrArgs = [NSMutableArray array];
    NSEnumerator *kenum = [sortedArgKeys objectEnumerator];
    NSString *k;
    while ((k = [kenum nextObject]) != nil) {
        [baseStrArgs addObject:[NSString stringWithFormat:@"%@=%@", k, OFEscapedURLStringFromNSStringWithExtraEscapedChars([[newArgs objectForKey:k] description], kEscapeChars)]];
    }
    [baseString appendString:OFEscapedURLStringFromNSStringWithExtraEscapedChars([baseStrArgs componentsJoinedByString:@"&"], kEscapeChars)];
    
    NSString *signature = OFHMACSha1Base64(signatureKey, baseString);
    [newArgs setObject:signature forKey:@"oauth_signature"];
    return newArgs;
}

@end