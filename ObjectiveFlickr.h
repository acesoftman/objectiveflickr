//
// ObjectiveFlickr.h
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

extern NSString *const OFFlickrReadPermission;
extern NSString *const OFFlickrWritePermission;
extern NSString *const OFFlickrDeletePermission;

@interface ObjectiveFlickr : NSObject

- (id)initWithAPIKey:(NSString *)apiKey sharedSecret:(NSString *)sharedSecret;

- (NSURL *)userAuthorizationURLWithRequestToken:(NSString *)requestToken
                            requestedPermission:(NSString *)permission;

- (void)fetchRequestTokenWithCallbackURL:(NSURL *)callbackURL
                                 success:(void (^)(NSString *requestToken))success
                                 failure:(void (^)(NSInteger statusCode, NSError *error))failure;

- (void)fetchAccessTokenWithRequestToken:(NSString *)requestToken
                                verifier:(NSString *)verifier
                                 success:(void (^)())success
                                 failure:(void (^)(NSInteger statusCode, NSError *error))failure;

- (void)sendWithMethod:(NSString *)method
                  path:(NSString *)path
             arguments:(NSDictionary *)arguments
               success:(void (^)(NSDictionary *responseDictionary))success
               failure:(void (^)(NSInteger statusCode, NSError *error))failure;

@property(nonatomic, readonly) NSString *key;
@property(nonatomic, readonly) NSString *sharedSecret;
@property(nonatomic, strong) NSString *oauthToken;
@property(nonatomic, strong) NSString *oauthTokenSecret;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *fullname;
@property(nonatomic, strong) NSString *userId;

@end

