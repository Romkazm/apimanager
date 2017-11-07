//
//  RKAPIManager.m
//  Bonnti-Restart
//
//  Created by Roman Kazmirchuk on 18.08.17.
//  Copyright © 2017 Roman Kazmirchuk. All rights reserved.
//

#import "RKAPIManager.h"
#import "RKConstant.h"
#import "RKKeychainManager.h"
#import "RKLocalDataManager.h"
#import "RKUtilitiesManager.h"

#import "RKSignInAnswer.h"
#import "RKSuggestionsAnswer.h"
#import "RKStylistsFilterOptions.h"
#import "RKHairType.h"

#import <AFNetworking.h>
#import <Firebase.h>

typedef enum {
    
    RKHTTPMethodGet     = 1,
    RKHTTPMethodPost    = 2,
    RKHTTPMethodDelete  = 3,
    RKHTTPMethodPatch   = 4,
    RKHTTPMethodPut     = 5
    
} RKHTTPMethod;

@implementation RKAPIManager

+ (id)sharedManager {
    
    static RKAPIManager *sharedAPIManager   = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedAPIManager    = [[self alloc] init];
        
    });
    
    return sharedAPIManager;
    
}

- (id)init {
    
    if (self = [super init]) {
        
        //        set property
        
    }
    return self;
    
}

- (void)requestWithUrlString:(NSString *)urlString
           withAuthorization:(BOOL)authorization
                  withParams:(NSDictionary *)params
                  withMethod:(RKHTTPMethod)method
         withProgressHandler:(void(^)(CGFloat progress))porgressHandler
       withCompletionHandler:(void(^)(RKApiAnswer *answer))completionHandler
            withErrorHandler:(void(^)(RKApiAnswer *answer))errorHandler {
    
//    NSLog(@"URL: %@\nParams:\n%@",
//          urlString,
//          params);
    
    AFHTTPSessionManager *manager   = [AFHTTPSessionManager manager];
    if (authorization) {

        NSString *token = [[RKKeychainManager sharedManager]
                           stringForKey:@"authenticationToken"];
        
        if (token.length > 0) {
            
            [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",
                                                 token]
                             forHTTPHeaderField:@"Authorization"];
            
        } else {
            
            errorHandler(nil);
            return;
            
        }
        
    }
    
    if (method == RKHTTPMethodGet) {
        
        [manager GET:urlString
          parameters:params
            progress:^(NSProgress * _Nonnull downloadProgress) {
                
                porgressHandler(downloadProgress.fractionCompleted);
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [[RKAPIManager sharedManager]
                 parseSuccessWithResponseObject:responseObject
                 withCompletionHandler:completionHandler
                 withErrorHandler:errorHandler];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [[RKAPIManager sharedManager]
                 parseFailureWithError:error
                 withErrorHandler:errorHandler];
                
            }];
        
    } else if (method == RKHTTPMethodPost) {
        
        NSMutableDictionary *normalParams   = [NSMutableDictionary dictionary];
        NSMutableDictionary *imageParams    = [NSMutableDictionary dictionary];
        for (NSString *key in params.allKeys) {
        
            if ([[params objectForKey:key]
                 isKindOfClass:[UIImage class]]) {
            
                [imageParams setObject:[params objectForKey:key]
                                forKey:key];
            
            } else {
            
                [normalParams setObject:[params objectForKey:key]
                                 forKey:key];
            
            }
        
        }
        
        [manager POST:urlString
           parameters:normalParams
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    
    for (NSString *key in imageParams.allKeys) {
    
        UIImage *image      = [imageParams objectForKey:key];
        NSData *imageData   = UIImageJPEGRepresentation(image, 1);
        
        [formData appendPartWithFileData:imageData
                                    name:key
                                fileName:@"cover.jpg"
                                mimeType:@"image/jpeg"];
    
    }
    
} progress:^(NSProgress * _Nonnull uploadProgress) {
    
    porgressHandler(uploadProgress.fractionCompleted);
    
} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
    [[RKAPIManager sharedManager]
     parseSuccessWithResponseObject:responseObject
     withCompletionHandler:completionHandler
     withErrorHandler:errorHandler];
    
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    
    [[RKAPIManager sharedManager]
     parseFailureWithError:error
     withErrorHandler:errorHandler];
    
}];
        
    } else if (method == RKHTTPMethodDelete) {
        
        [manager DELETE:urlString
             parameters:params
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    [[RKAPIManager sharedManager]
                     parseSuccessWithResponseObject:responseObject
                     withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    [[RKAPIManager sharedManager]
                     parseFailureWithError:error
                     withErrorHandler:errorHandler];
                    
                }];
        
    } else if (method == RKHTTPMethodPatch) {
    
        [manager PATCH:urlString
            parameters:params
               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   
                   [self parseSuccessWithResponseObject:responseObject
                                  withCompletionHandler:completionHandler
                                       withErrorHandler:errorHandler];
                   
               } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   
                   [self parseFailureWithError:error
                              withErrorHandler:errorHandler];
                   
               }];
    
    } else if (method == RKHTTPMethodPut) {
        
        [manager PUT:urlString
          parameters:params
             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   
                   [self parseSuccessWithResponseObject:responseObject
                                  withCompletionHandler:completionHandler
                                       withErrorHandler:errorHandler];
                   
             } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   
                   [self parseFailureWithError:error
                              withErrorHandler:errorHandler];
                   
             }];
        
    }
    
}

- (void)parseSuccessWithResponseObject:(id)responseObject
                 withCompletionHandler:(void(^)(RKApiAnswer *answer))completionHandler
                      withErrorHandler:(void(^)(RKApiAnswer *answer)) errorHandler {

    NSLog(@"[Request success]: %@",
          responseObject);
    NSError *parserError;
    RKApiAnswer *answer = [[RKApiAnswer alloc]
                           initWithDictionary:responseObject
                           error:&parserError];
    
    if (!parserError) {
    
        if (answer.errorsDict.allKeys.count == 0) {
        
            completionHandler(answer);
        
        } else {
        
            errorHandler(answer);
        
        }
    
    } else {
        
        errorHandler([RKApiAnswer unknownErrorApiAnswer]);
    
    }

}

- (void)parseFailureWithError:(NSError *)error
             withErrorHandler:(void(^)(RKApiAnswer *answer))errorHandler {

    NSLog(@"[Request failure]: %@",
          error.userInfo);
    NSString *htmlString    = [[NSString alloc]
                               initWithData:[error.userInfo objectForKey:@"com.alamofire.serialization.response.error.data"]
                               encoding:NSUTF8StringEncoding];
    NSLog(@"[HTML]: %@",
          htmlString);
    NSInteger statusCode    = [[[error userInfo]
                                objectForKey:AFNetworkingOperationFailingURLResponseErrorKey]
                               statusCode];
    
    if (statusCode > 0) {
    
        NSData *responseData    = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *response  = [NSJSONSerialization JSONObjectWithData:responseData
                                                                  options:0
                                                                    error:&error];

        NSError *parseError;
        RKApiAnswer *answer = [[RKApiAnswer alloc]
                               initWithDictionary:response
                               error:&parseError];
        
        if (!parseError) {
        
            errorHandler(answer);
        
        } else {
            
            errorHandler([RKApiAnswer unknownErrorApiAnswer]);
        
        }
    
    } else {
    
        RKApiAnswer *answer = [[RKApiAnswer alloc]
                               init];
        answer.errorsDict   = @{@"connection":  @[[RKConstant noInternetErrorText]]};
        
        errorHandler(answer);
    
    }

}

#pragma mark - Utility -

- (NSString *)stringFromDate:(NSDate *)date {

    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc]
                                       init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    NSString *dateString    = [dateFormatter stringFromDate:date];
    
    NSLog(@"[Date string]: %@",
          dateString);
    
    return dateString;

}

#pragma mark - Launch -

- (void)updateConstants {

    [self updateStylistsFilterOptionsWithCompletionHandler:^{}];
    [self updateEventCategoriesWithCompletionHandler:^{}];
    [self updateEventReportReasons];
    [self updateComthruStylesWithCompletionHandler:^{}];
    [self updateHairTypesWithCompletionHandler:^{}];

}

- (void)updateStylistsFilterOptionsWithCompletionHandler:(void(^)(void))completionHandler {

    [self requestWithUrlString:[RKConstant stylistsFilterOptionsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             NSError *parseError;
             RKStylistsFilterOptions *options   = [[RKStylistsFilterOptions alloc]
                                                   initWithDictionary:answer.dataDict
                                                   error:&parseError];
             if (!parseError) {
             
                 [[RKLocalDataManager sharedManager]
                  saveStylistsFilterOptions:options];
                 
                 completionHandler();
             
             } else {
             
                 completionHandler();
             
             }
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             completionHandler();
             
         }];

}

- (void)updateEventCategoriesWithCompletionHandler:(void(^)(void))completionHandler {

    [self requestWithUrlString:[RKConstant eventCategoriesUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             NSError *parseError;
             NSArray<RKEventCategory *> *categories = [RKEventCategory arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"categories"]
                                                                                               error:&parseError];
             if (!parseError) {
             
                 [[RKLocalDataManager sharedManager]
                  saveEventCategories:categories];
                 completionHandler();
             
             } else {
             
                 completionHandler();
             
             }
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             completionHandler();
             
         }];

}

- (void)updateComthruStylesWithCompletionHandler:(void(^)(void))completionHandler {

    [self requestWithUrlString:[RKConstant combthruStylesUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKStyle *> *styles   = [RKStyle arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"styles"]
                                                                               error:&parseError];
               if (!parseError) {
               
                   [[RKLocalDataManager sharedManager]
                    saveCombthruStyles:styles];
                   
                   completionHandler();
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {}];

}

- (void)updateHairTypesWithCompletionHandler:(void(^)(void))completionHandler {
    
    [self requestWithUrlString:[RKConstant getHairTypesUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKHairType *> *hairTypes = [RKHairType arrayOfModelsFromDictionaries:answer.dataArray
                                                                                      error:&parseError];
               if (!parseError) {
                   
                   [[RKLocalDataManager sharedManager]
                    saveHairTypes:hairTypes];
                   
                   completionHandler();
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
           }];
    
}

#pragma mark - Authorization -

- (void)signInWithUsername:(NSString *)username
              withPassword:(NSString *)password
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {

    NSDictionary *params    = @{@"username":    username,
                                @"password":    password};
    
    [self requestWithUrlString:[RKConstant signInUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)signInWithFacebookToken:(NSString *)token
          withCompletionHandler:(void(^)(void))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"code":    token};
    
    [self requestWithUrlString:[RKConstant signInFacebookUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)signInWithTwitterToken:(NSString *)token
             withTwitterSecret:(NSString *)secret
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"code":    token,
                                @"secret":  secret};
    [self requestWithUrlString:[RKConstant signInTwitterUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)signUpWithUsername:(NSString *)username
              withPassword:(NSString *)password
             withFirstName:(NSString *)firstName
              withLastName:(NSString *)lastName
                 withEmail:(NSString *)email
           withAccountType:(NSString *)accountType
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"username":        username,
                                @"password":        password,
                                @"first_name":      firstName,
                                @"last_name":       lastName,
                                @"email":           email,
                                @"account_type":    accountType};
    
    [self requestWithUrlString:[RKConstant signUpUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)signUpWithFacebookToken:(NSString *)token
                withAccountType:(NSString *)accountType
          withCompletionHandler:(void(^)(void))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"code":            token,
                                @"account_type":    accountType};
    
    [self requestWithUrlString:[RKConstant signUpFacebookUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)signUpWithTwitterToken:(NSString *)token
                    withSecret:(NSString *)secret
                withAccountType:(NSString *)accountType
          withCompletionHandler:(void(^)(void))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"code":            token,
                                @"secret":          secret,
                                @"account_type":    accountType};
    
    [self requestWithUrlString:[RKConstant signUpTwitterUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             [self loginWithApiAnswer:answer
                withCompletionHandler:completionHandler
                     withErrorHandler:errorHandler];
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];
    
}

- (void)loginWithApiAnswer:(RKApiAnswer *)answer
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSError *parseError;
    RKSignInAnswer *signIn = [[RKSignInAnswer alloc]
                              initWithDictionary:answer.dataDict
                              error:&parseError];
    if (!parseError) {
        
        [[RKLocalDataManager sharedManager]
         loginWithMyUser:signIn.myUser
         withToken:signIn.token];
        
        [self updateConstants];
        
        [self notificationRegisterWithCompletionHandler:^{
            
            if (signIn.myUser.isConsumer) {
                
                [self getMyClientProfileWithCompletionHandler:^(RKClientProfile *profile) {
                    
                    completionHandler();
                    
                } withErrorHandler:^(NSString *errorMessage) {
                    
                    errorHandler(errorMessage);
                    
                }];
                
            } else {
                
                [self getStylistMyProfileWithCompletionHandler:^(RKStylistMyProfile *myProfile) {
                    
                    completionHandler();
                    
                } withErrorHandler:^(NSString *errorMessage) {
                    
                    errorHandler(errorMessage);
                    
                }];
                
            }
             
         } withErrorHandler:^(NSString *errorMessage) {
             
             errorHandler(errorMessage);
             
         }];
        
        
    } else {
        
        errorHandler([RKConstant unknownErrorText]);
        
    }


}

- (void)resetPasswordRequestCodeWithUsername:(NSString *)username
                       withCompletionHandler:(void(^)(void))completionHandler
                            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"login":   username};
    [self requestWithUrlString:[RKConstant resetPasswordRequestCodeUrl]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             completionHandler();
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)resetPasswordChangeWithCode:(NSString *)code
                       withPassword:(NSString *)password
                withPasswordConfirm:(NSString *)passwordConfirm
              withCompletionHandler:(void(^)(void))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"code":                    code,
                                @"password":                password,
                                @"password_confirmation":   passwordConfirm};
    [self requestWithUrlString:[RKConstant resetPasswordChange]
             withAuthorization:NO
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             completionHandler();
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

#pragma mark - Stylists -

- (void)getStylistsWithLatitude:(CGFloat)latitude
                  withLongitude:(CGFloat)longitude
                     withOffset:(NSInteger)offset
          withCompletionHandler:(void(^)(NSArray<RKStylist *> *stylists))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"latitude":    @(latitude),
                                @"longitude":   @(longitude),
                                @"offset":      @(offset)};
    [self requestWithUrlString:[RKConstant stylistsNearYouUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             NSError *parseError;
             NSArray<RKStylist *> *stylists = [RKStylist arrayOfModelsFromDictionaries:answer.dataArray
                                                                                 error:&parseError];
             if (!parseError) {
                 
                 completionHandler(stylists);
                 
             } else {
                 
                 errorHandler([RKConstant unknownErrorText]);
                 
             }
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)getStylistWithStylistId:(NSString *)stylistId
         withCompletionHandeler:(void(^)(RKStylist *stylist))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": stylistId};
    [self requestWithUrlString:[RKConstant getStylistUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKStylist *stylist   = [[RKStylist alloc]
                                       initWithDictionary:[answer.dataDict objectForKey:@"profile"]
                                       error:&parseError];
               if (!parseError) {
               
                   completionHandler(stylist);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)searchStylistWithQuery:(NSString *)query
                  withDistance:(NSInteger)distance
                     withPrice:(CGFloat)price
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
           withCurrentLocation:(BOOL)currentLocation
                    withOffset:(NSInteger)offset
         withCompletionHandler:(void(^)(NSArray<RKStylist *> *stylists))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"query":                 query,
                                                                                  @"offset":                @(offset),
                                                                                  @"latitude":              @(latitude),
                                                                                  @"longitude":             @(longitude),
                                                                                  @"by_current_location":   currentLocation ? @1 : @0
                                                                                  }];
    if (distance >= 0) {
    
        [params setObject:@(distance)
                   forKey:@"distance"];
    
    }
    if (price >=0) {
    
        [params setObject:@(price)
                   forKey:@"price"];
    
    }
    
    [self requestWithUrlString:[RKConstant stylistsSearchUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             NSError *parseError;
             NSArray<RKStylist *> *stylists = [RKStylist arrayOfModelsFromDictionaries:answer.dataArray
                                                                                 error:&parseError];
             if (!parseError) {
             
                 completionHandler(stylists);
             
             } else {
             
                 errorHandler([RKConstant unknownErrorText]);
             
             }
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];

}

- (void)searchStylistsSuggestionWithQuery:(NSString *)query
                    withCompletionHandler:(void(^)(NSArray<NSString *> *suggestions))completionHandler
                         withErrorHandler:(void(^)(void))errorHandler {

    NSDictionary *params    = @{@"query":   query};
    [self requestWithUrlString:[RKConstant stylistsSearchSuggestionsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {}
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             NSError *parseError;
             RKSuggestionsAnswer *suggestionsAnswer = [[RKSuggestionsAnswer alloc]
                                                       initWithDictionary:answer.dataDict
                                                       error:&parseError];
             if (!parseError) {
             
                 completionHandler(suggestionsAnswer.suggestions);
             
             } else {
             
                 errorHandler();
             
             }
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler();
             
         }];

}

- (void)createStylistReviewWithStylistId:(NSString *)stylistId
                              withRating:(NSInteger)rating
                             withComment:(NSString *)comment
                   withCompletionHandler:(void(^)(RKReview *review))completionHandler
                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": stylistId,
                                @"rating":  @(rating),
                                @"comment": comment};
    [self requestWithUrlString:[RKConstant stylistAddReviewUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKReview *review = [[RKReview alloc]
                                   initWithDictionary:[answer.dataDict objectForKey:@"review"]
                                   error:&parseError];
               if (!parseError) {
               
                   completionHandler(review);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Client -

- (void)getMyClientProfileWithCompletionHandler:(void(^)(RKClientProfile *profile))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant getMyClientProfileUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKClientProfile *clientProfile   = [[RKClientProfile alloc]
                                                   initWithDictionary:[answer.dataDict objectForKey:@"profile"]
                                                   error:&parseError];
               if (!parseError) {
               
                   [[RKLocalDataManager sharedManager]
                    saveClientMyProfile:clientProfile];
                   completionHandler(clientProfile);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getClientProfileWithClientId:(NSString *)clientId
               withCompletionHandler:(void(^)(RKClientProfile *profile))completionHandler
                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": clientId};
    [self requestWithUrlString:[RKConstant getClientProfileUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKClientProfile *clientProfile   = [[RKClientProfile alloc]
                                                   initWithDictionary:[answer.dataDict objectForKey:@"profile"]
                                                   error:&parseError];
               if (!parseError) {
                   
                   completionHandler(clientProfile);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Events -

- (void)createEventWithTitle:(NSString *)title
                 withDetails:(NSString *)details
                 withAddress:(NSString *)address
                 withWebsite:(NSString *)website
               withStartDate:(NSDate *)startDate
                 withEndDate:(NSDate *)endDate
                withCategory:(NSString *)category
            withOnlyStylists:(BOOL)onlyStylist
              withCoverImage:(UIImage *)coverImage
               withLongitude:(NSString *)longitude
                withLatitude:(NSString *)latitude
       withCompletionHandler:(void(^)(void))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"title":   title,
                                @"details": details,
                                @"address": address,
                                @"web_site":    website,
                                @"starts_at":   [self stringFromDate:startDate],
                                @"ends_at":     [self stringFromDate:endDate],
                                @"category":    category,
                                @"only_for_stylists":   onlyStylist ? @1 : @0,
                                @"cover":               coverImage,
                                @"latitude":            latitude,
                                @"longitude":           longitude};

    [self requestWithUrlString:[RKConstant createEventUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           
               NSLog(@"[CREATE EVENT PROGRESS]: %lf",
                     progress);
           
           }
         withCompletionHandler:^(RKApiAnswer *answer) {
             
             completionHandler();
             
         } withErrorHandler:^(RKApiAnswer *answer) {
             
             errorHandler(answer.errorMessage);
             
         }];
    
}

- (void)updateEventWithEventId:(NSString *)eventId
                     withTitle:(NSString *)title
                   withDetails:(NSString *)details
                   withAddress:(NSString *)address
                   withWebsite:(NSString *)website
                 withStartDate:(NSDate *)startDate
                   withEndDate:(NSDate *)endDate
                  withCategory:(NSString *)category
              withOnlyStylists:(BOOL)onlyStylist
                withCoverImage:(UIImage *)coverImage
                 withLongitude:(NSString *)longitude
                  withLatitude:(NSString *)latitude
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"id":                eventId,
                                                                                  @"title":             title,
                                                                                  @"details":           details,
                                                                                  @"address":           address,
                                                                                  @"web_site":          website,
                                                                                  @"starts_at":         [self stringFromDate:startDate],
                                                                                  @"ends_at":           [self stringFromDate:endDate],
                                                                                  @"category":          category,
                                                                                  @"only_for_stylists": onlyStylist ? @1 : @0,
                                                                                  @"latitude":          latitude,
                                                                                  @"longitude":         longitude}];
    if (coverImage) {
    
        [params setObject:coverImage
                   forKey:@"cover"];
    
    }
    
    [self requestWithUrlString:[RKConstant updateEventUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)parseEventsWithApiAnswer:(RKApiAnswer *)answer
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSError *parseError;
    NSArray<RKEvent *> *events  = [RKEvent arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"events"]
                                                                   error:&parseError];
    if (!parseError) {
    
        completionHandler(events);
    
    } else {
    
        errorHandler([RKConstant unknownErrorText]);
    
    }

}

- (void)getAllEventsWithOffset:(NSInteger)offset
         withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
              withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {

    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant allEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getnearYouEventsWithOffset:(NSInteger)offset
                      withLatitude:(CGFloat)latitude
                     withLongitude:(CGFloat)longitude
             withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                  withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"offset":      @(offset),
                                @"latitude":    @(latitude),
                                @"longitude":   @(longitude)};
    [self requestWithUrlString:[RKConstant nearYouEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)getPostsEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant postsEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)getGoingEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant goingEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)getMaybeEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant maybeEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)searchEventsWithOffset:(NSInteger)offset
                     withQuery:(NSString *)query
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
                withSortByDate:(BOOL)sortByDate
                  withDistance:(CGFloat)distance
         withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params    = [NSMutableDictionary dictionaryWithDictionary:@{@"offset":         @(offset),
                                                                                     @"query":          query,
                                                                                     @"latitude":       @(latitude),
                                                                                     @"longitude":      @(longitude),
                                                                                     @"sort_by_date":   sortByDate ? @1 : @0}];
    if (distance >= 0) {
    
        [params setObject:@(distance)
                   forKey:@"distance"];
    
    }
    [self requestWithUrlString:[RKConstant searchEventsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseEventsWithApiAnswer:answer
                        withCompletionHandler:completionHandler
                             withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postEventGoingWithEventId:(NSString *)eventId
                        withGoing:(BOOL)going {

    NSDictionary *params    = @{@"id":    eventId};
    [self requestWithUrlString:going ? [RKConstant postEventGoingUrl] : [RKConstant deleteEventGoingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:going ? RKHTTPMethodPost : RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
           } withErrorHandler:^(RKApiAnswer *answer) {}];

}

- (void)postEventMaybeWithEventId:(NSString *)eventId
                        withMaybe:(BOOL)maybe {

    NSDictionary *params    = @{@"id":    eventId};
    [self requestWithUrlString:maybe ? [RKConstant postEventMaybeUrl] : [RKConstant deleteEventMaybeUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:maybe ? RKHTTPMethodPost : RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
           } withErrorHandler:^(RKApiAnswer *answer) {}];

}

- (void)postReportWithEventId:(NSString *)eventId
                   withReason:(NSString *)reason
        withCompletionHandler:(void(^)(NSString *message))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":      eventId,
                                @"reason":  reason};
    
    [self requestWithUrlString:[RKConstant reportEventUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler(answer.message);
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateEventReportReasons {

    [self requestWithUrlString:[RKConstant reportReasonsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKReportReason *> *reportReasons = [RKReportReason arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"reasons"]
                                                                                                  error:&parseError];
               if (!parseError) {
               
                   [[RKLocalDataManager sharedManager]
                    saveEventReportReasons:reportReasons];
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
           }];

}

- (void)deleteEventWithEventId:(NSString *)eventId
         withCompletionHandler:(void(^)(NSString *message))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  eventId};
    [self requestWithUrlString:[RKConstant deleteEventUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler(answer.message);
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Services -

- (void)addressSuggestionsWithQuery:(NSString *)query
              withCompletionHandler:(void(^)(NSArray<RKAddressSuggestion *> *addressSuggestions))completionhandler
                   withErrorHandler:(void(^)(void))errorHandler {

    NSDictionary *params    = @{@"query":   query};
    [self requestWithUrlString:[RKConstant addressSuggestionsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKAddressSuggestion *> *suggestions  = [RKAddressSuggestion arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"addresses"]
                                                                                                           error:&parseError];
               if (!parseError) {
               
                   completionhandler(suggestions);
               
               } else {
               
                   errorHandler();
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler();
               
           }];

}

- (void)usernameSuggestionsWithQuery:(NSString *)query
               withCompletionHandler:(void(^)(NSArray<RKUserSuggestion *> *suggestions))completionHandler
                    withErrorHandler:(void(^)(void))errorHandler {

    NSDictionary *params    = @{@"query":   query};
    [self requestWithUrlString:[RKConstant usernameSuggestionsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKUserSuggestion *> *suggestions = [RKUserSuggestion arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"users"]
                                                                                                    error:&parseError];
               if (!parseError) {
               
                   completionHandler(suggestions);
               
               } else {
               
                   errorHandler();
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler();
               
           }];

}

#pragma mark - Settings -

- (void)getStylistMyProfileWithCompletionHandler:(void(^)(RKStylistMyProfile *myProfile))completionHandler
                                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant stylistMyProfileUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKStylistMyProfile *myProfile    = [[RKStylistMyProfile alloc]
                                                   initWithDictionary:[answer.dataDict objectForKey:@"profile"]
                                                   error:&parseError];
               if (!parseError) {
               
                   [[RKLocalDataManager sharedManager]
                    saveStylistMyProfile:myProfile];
                   completionHandler(myProfile);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateStylistProfileWithFirstName:(NSString *)firstName
                             withLastName:(NSString *)lastName
                              withAddress:(NSString *)address
                             withLatitude:(CGFloat)latitude
                            withLongitude:(CGFloat)longitude
                                 withName:(NSString *)name
                          withPhoneNumber:(NSString *)phoneNumber
                              withWebsite:(NSString *)website
                                  withBio:(NSString *)bio
                             withLicensed:(NSInteger)licensed
                          withLicenseDate:(NSDate *)licenseDate
                         withLicenseState:(NSString *)licenseState
                         withProfileImage:(UIImage *)profileImage
                           withCoverImage:(UIImage *)coverImage
                         withSpecialities:(NSArray<NSString *> *)specialities
                    withCompletionHandler:(void(^)(RKStylistMyProfile *myProfile))completionHandler
                        withErrorHandlerl:(void(^)(NSString *errorMessage))errorHandler {

    [self updateStylistProfileWithFirstName:firstName
                               withLastName:lastName
                                withAddress:address
                               withLatitude:latitude
                              withLongitude:longitude
                                   withName:name
                            withPhoneNumber:phoneNumber
                                withWebsite:website
                                    withBio:bio
                               withLicensed:licensed
                            withLicenseDate:licenseDate
                           withLicenseState:licenseState
                           withSpecialities:specialities
      withCompletionHandler:^(RKStylistMyProfile *myProfile) {
          
          [self updateStylistCoverPhotoWithImage:coverImage
           withCompletionHandler:^{
               
               [self updateStylistProfilePhotoWithImage:profileImage
                  withCompletionHandler:^{
                      
                      completionHandler(myProfile);
                      
                  } withErrorHandler:^(NSString *errorMessage) {
                      
                      errorHandler(errorMessage);
                      
                  }];
               
           } withErrorHandler:^(NSString *errorMessage) {
               
               errorHandler(errorMessage);
               
           }];
          
      } withErrorHandlerl:^(NSString *errorMessage) {
          
          errorHandler(errorMessage);
          
      }];

}

- (void)updateStylistProfileWithFirstName:(NSString *)firstName
                             withLastName:(NSString *)lastName
                              withAddress:(NSString *)address
                             withLatitude:(CGFloat)latitude
                            withLongitude:(CGFloat)longitude
                                 withName:(NSString *)name
                          withPhoneNumber:(NSString *)phoneNumber
                              withWebsite:(NSString *)website
                                  withBio:(NSString *)bio
                             withLicensed:(NSInteger)licensed
                          withLicenseDate:(NSDate *)licenseDate
                         withLicenseState:(NSString *)licenseState
                         withSpecialities:(NSArray<NSString *> *)specialities
                    withCompletionHandler:(void(^)(RKStylistMyProfile *myProfile))completionHandler
                        withErrorHandlerl:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"first_name":    firstName,
                                                                                  @"last_name":     lastName,
                                                                                  @"name":          name,
                                                                                  @"phone_number":  phoneNumber,
                                                                                  @"web_site":      website,
                                                                                  @"bio":           bio}];
    for (NSInteger i = 0; i < specialities.count; i ++) {
    
        [params setObject:[specialities objectAtIndex:i]
                   forKey:[NSString stringWithFormat:@"specialities[%ld]",
                           (long)i]];
    
    }
    if (address.length > 0) {
    
        [params setObject:address
                   forKey:@"address"];
        [params setObject:@(latitude)
                   forKey:@"latitude"];
        [params setObject:@(longitude)
                   forKey:@"longitude"];
    
    }
    if (licensed == 1 && licenseState) {
    
        [params setObject:@1
                   forKey:@"licensed"];
        [params setObject:licenseState
                   forKey:@"license_state"];
        [params setObject:[[RKUtilitiesManager sharedManager]
                           stringFromDate:licenseDate
                           withFormat:@"yyyy-MM-dd"]
                   forKey:@"license_expiration"];
    
    } else if (licensed == 0) {
    
        [params setObject:@0
                   forKey:@"licensed"];
    
    }
    
    [self requestWithUrlString:[RKConstant updateStylistMyProfileUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPatch
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKStylistMyProfile *myProfile    = [[RKStylistMyProfile alloc]
                                                   initWithDictionary:[answer.dataDict objectForKey:@"profile"]
                                                   error:&parseError];
               if (!parseError) {
                   
                   [[RKLocalDataManager sharedManager]
                    saveStylistMyProfile:myProfile];
                   completionHandler(myProfile);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateStylistCoverPhotoWithImage:(UIImage *)image
                   withCompletionHandler:(void(^)(void))completionHandler
                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    if (!image) {
    
        completionHandler();
        return;
    
    }
    
    NSDictionary *params    = @{@"file":    image};
    [self requestWithUrlString:[RKConstant updateStylistCoverPhotoUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Cover photo error]");
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateStylistProfilePhotoWithImage:(UIImage *)image
                     withCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    if (!image) {
    
        completionHandler();
        return;
    
    }
    
    NSDictionary *params    = @{@"file":    image};
    [self requestWithUrlString:[RKConstant updateStylistProfilePhotoUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Profile photo error]");
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)addStylistServiceWithTitle:(NSString *)title
                         withPrice:(CGFloat)price
                      withDuration:(NSInteger)duration
             withCompletionHandler:(void(^)(void))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"title":       title,
                                @"price":       @(price),
                                @"duration":    @(duration)};
    [self requestWithUrlString:[RKConstant addStylistServiceUrl
                                ] withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateStylistServiceWithServiceId:(NSString *)serviceId
                                withTitle:(NSString *)title
                                withPrice:(CGFloat)price
                             withDuration:(NSInteger)duration
                    withCompletionHandler:(void(^)(void))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":      serviceId,
                                @"title":       title,
                                @"price":       @(price),
                                @"duration":    @(duration)};
    [self requestWithUrlString:[RKConstant updateStylistServiceUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPut
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deleteStylistServiceWithServiceId:(NSString *)serviceId
                    withCompletionHandler:(void(^)(void))completionhandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  serviceId};
    [self requestWithUrlString:[RKConstant deleteStylistServiceUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionhandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateStylistHoursWithHours:(RKHours *)hours
              withCompletionHandler:(void(^)(void))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"days[monday][on]":        hours.monday.on ? @1 : @0,
                                @"days[monday][from]":      hours.monday.from,
                                @"days[monday][to]":        hours.monday.to,
                                @"days[tuesday][on]":       hours.tuesday.on ? @1 : @0,
                                @"days[tuesday][from]":     hours.tuesday.from,
                                @"days[tuesday][to]":       hours.tuesday.to,
                                @"days[wednesday][on]":     hours.wednesday.on ? @1 : @0,
                                @"days[wednesday][from]":   hours.wednesday.from,
                                @"days[wednesday][to]":     hours.wednesday.to,
                                @"days[thursday][on]":      hours.thursday.on ? @1 : @0,
                                @"days[thursday][from]":    hours.thursday.from,
                                @"days[thursday][to]":      hours.thursday.to,
                                @"days[friday][on]":        hours.friday.on ? @1 : @0,
                                @"days[friday][from]":      hours.friday.from,
                                @"days[friday][to]":        hours.friday.to,
                                @"days[saturday][on]":      hours.saturday.on ? @1 : @0,
                                @"days[saturday][from]":    hours.saturday.from,
                                @"days[saturday][to]":      hours.saturday.to,
                                @"days[sunday][on]":        hours.sunday.on ? @1 : @0,
                                @"days[sunday][from]":      hours.sunday.from,
                                @"days[sunday][to]":        hours.sunday.to};
    [self requestWithUrlString:[RKConstant updateStylistHoursUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPut
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKHours *hours   = [[RKHours alloc]
                                   initWithDictionary:[answer.dataDict objectForKey:@"hours"]
                                   error:&parseError];
               if (!parseError) {
               
                   RKStylistMyProfile *myProfile    = [[RKLocalDataManager sharedManager]
                                                       getStylistMyProfile];
                   myProfile.hours                  = hours;
                   [[RKLocalDataManager sharedManager]
                    saveStylistMyProfile:myProfile];
                   
                   completionHandler();
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)updateAccountSettingsWithFirstName:(NSString *)firstName
                              withLastName:(NSString *)lastName
                              withUsername:(NSString *)username
                                 withEmail:(NSString *)email
                           withPhoneNumber:(NSString *)phoneNumber
                                withGender:(NSString *)gender
                             withBirthdate:(NSDate *)birthdate
                              withLicensed:(NSInteger)licensed
                         withLicensedState:(NSString *)licensedState
                           withLicensedExp:(NSDate *)licensedExp
                     withCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
                                   @{@"first_name":      firstName,
                                     @"last_name":       lastName,
                                     @"username":        username,
                                     @"email":           email,
                                     @"phone_number":    phoneNumber,
                                     @"gender":          gender}];
//    @"date_of_birth":   [[RKUtilitiesManager sharedManager]
//                         stringFromDate:birthdate
//                         withFormat:@"yyyy-MM-dd"
    if (licensed == 1 &&
        licensedState &&
        licensedExp) {
    
        [params setObject:@1
                   forKey:@"licensed"];
        [params setObject:licensedState
                   forKey:@"license_state"];
        [params setObject:[[RKUtilitiesManager sharedManager]
                           stringFromDate:licensedExp
                           withFormat:@"yyyy-MM-dd"]
                   forKey:@"license_expiration"];
    
    } else if (licensed == 0) {
    
        [params setObject:@0
                   forKey:@"licensed"];
    
    }
    [self requestWithUrlString:[RKConstant updateAccountSettingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPatch
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword
                      withNewPassword:(NSString *)password
                  withConfirmPassword:(NSString *)confirmPassword
                withCompletionHandler:(void(^)(void))completionHandler
                     withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"current_password":            oldPassword,
                                @"new_password":                password,
                                @"new_password_confirmation":   confirmPassword};
    [self requestWithUrlString:[RKConstant changePasswordUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postClientProfileWithFirstName:(NSString *)firstName
                          withLastName:(NSString *)lastName
                              withMale:(BOOL)male
                     withHairTypeIdent:(NSString *)hairTypeIdent
                         withBirthDate:(NSDate *)birthDate
                               withBio:(NSString *)bio
                      withProfileImage:(UIImage *)profileImage
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"first_name":    firstName,
                                                                                  @"last_name":     lastName,
                                                                                  @"gender":        male ? @"male" : @"female",
                                                                                  @"bio":           bio}];
    if (hairTypeIdent) {
        
        [params setObject:hairTypeIdent
                   forKey:@"hair_type"];
        
    }
    if (birthDate) {
        
        [params setObject:[[RKUtilitiesManager sharedManager]
                           stringFromDate:birthDate
                           withLocaleString:nil
                           withTimeZoneString:@"UTC"
                           withFormat:@"yyyy-MM-dd"]
                    forKey:@"date_of_birth"];
        
    }
    [self requestWithUrlString:[RKConstant postClientProfileUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPatch
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self postClientProfilePhotoWithImage:profileImage
                               withCompletionHandler:^{
                                   
                                   completionHandler();
                                   
                               } withErrorHandler:^(NSString *errorMessage) {
                                   
                                   errorHandler(errorMessage);
                                   
                               }];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)postClientProfilePhotoWithImage:(UIImage *)image
                  withCompletionHandler:(void(^)(void))completionHandler
                       withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    if (!image) {
        
        completionHandler();
        
        return;
        
    }
    
    NSDictionary *params    = @{@"file":    image};
    [self requestWithUrlString:[RKConstant userUpdateProfilePhotoUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteStylistProfileImageWithCompletionHandler:(void(^)(void))completionHandler
                                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant deleteStylistProfilePhotoUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteStylistCoverImageWithCompletionHandler:(void(^)(void))completionHandler
                                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant deleteStylistCoverPhotoUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteClientProfileImageWithCompletionHandler:(void(^)(void))completionHandler
                                     withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant deleteClientProfilePhotoUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteAccountWithCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    RKMyUser *myUser    = [[RKLocalDataManager sharedManager]
                           getMyUser];
    if (myUser.isConsumer) {
        
        [self deleteCLientAccountWithCompletionHandler:^{
            
            completionHandler();
            
        } withErrorHandler:^(NSString *errorMessage) {
            
            errorHandler(errorMessage);
            
        }];
        
    } else {
        
        [[RKAPIManager sharedManager]
         deleteStylistAccountWithCompletionHandler:^{
             
             completionHandler();
             
         } withErrorHandler:^(NSString *errorMessage) {
             
             errorHandler(errorMessage);
             
         }];
        
    }
    
}

- (void)deleteStylistAccountWithCompletionHandler:(void(^)(void))completionHandler
                                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant deleteAccountStylistUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteCLientAccountWithCompletionHandler:(void(^)(void))completionHandler
                                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant deleteAccountClientUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

#pragma mark - Combthru -

- (void)getCombthrusWithOffset:(NSInteger)offset
                    withNearMe:(BOOL)nearMe
              withStylistsOnly:(BOOL)stylistsOnly
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
         withCompletionHandler:(void(^)(NSArray<RKCombthru *> *combthrus))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"offset":        @0,
                                                                                  @"near_me":       nearMe ? @1 : @0,
                                                                                  @"stylist_only":  stylistsOnly ? @1 : @0,
                                                                                  @"latitude":      @(latitude),
                                                                                  @"longitude":     @(longitude)}];
    [self requestWithUrlString:[RKConstant combthrusUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseCombthrusWithApiAnswer:answer
                           withCompletionHandler:completionHandler
                                withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getCombthrusWithTags:(BOOL)tags
                   withPosts:(BOOL)posts
                   withSaves:(BOOL)saves
               withStylistId:(NSString *)stylistId
                  withOffset:(NSInteger)offset
       withCompletionHandler:(void(^)(NSArray<RKCombthru *> *combthrus))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params    = [NSMutableDictionary dictionaryWithDictionary:@{@"offset":  @(offset)}];
    if (stylistId) {
    
        [params setObject:stylistId
                   forKey:@"user_id"];
    
    }
    NSString *urlString;
    if (tags && !stylistId) {
    
        urlString   = [RKConstant tagCombthrusUrl];
    
    } else if (posts && !stylistId) {
    
        urlString   = [RKConstant myCombthrusUrl];
    
    } else if (saves && !stylistId) {
    
        urlString   = [RKConstant savedCombthrusUrl];
    
    } else if (tags && stylistId) {
    
        urlString   = [RKConstant userTagCombthrusUrl];
    
    } else if (posts && stylistId) {
    
        urlString   = [RKConstant userPostCombthrusUrl];
    
    }
    [self requestWithUrlString:urlString
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [self parseCombthrusWithApiAnswer:answer
                           withCompletionHandler:completionHandler
                                withErrorHandler:errorHandler];
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)parseCombthrusWithApiAnswer:(RKApiAnswer *)answer
              withCompletionHandler:(void(^)(NSArray<RKCombthru *> *combthrus))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSError *parseError;
    NSArray<RKCombthru *> *combthrus = [RKCombthru arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"combs"]
                                                                           error:&parseError];
    if (!parseError) {
    
        completionHandler(combthrus);
    
    } else {
    
        errorHandler([RKConstant unknownErrorText]);
    
    }

}

- (void)postCombthruBookmarkWithIsBookmarked:(BOOL)isBookmarked
                              withCombthruId:(NSString *)combthruId
                       withCompletionHandler:(void(^)(void))completionHandler
                            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"comb_id": combthruId};
    [self requestWithUrlString:isBookmarked ? [RKConstant combthruAddBookmarkUrl] : [RKConstant combthruDeleteBookmarkUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:isBookmarked ? RKHTTPMethodPost : RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)likeCombthruWithCombthruId:(NSString *)combthruId {

    NSDictionary *params    = @{@"comb_id": combthruId};
    [self requestWithUrlString:[RKConstant likeCombthruUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Like comb] success");
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Like comb] Error: %@",
                     answer.errorMessage);
               
           }];

}

- (void)dislikeCombthruWithCombthruId:(NSString *)combthruId {
    
    NSDictionary *params    = @{@"comb_id": combthruId};
    [self requestWithUrlString:[RKConstant dislikeCombthruUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Disike comb] success");
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Dislike comb] Error: %@",
                     answer.errorMessage);
               
           }];
    
}

- (void)reportCombthruWithReason:(NSString *)reason
                  withCombthruId:(NSString *)combthruId
           withCompletionHandler:(void(^)(NSString *message))completionHandler
                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"comb_id": combthruId,
                                @"reason":  reason};
    [self requestWithUrlString:[RKConstant reportCombthruUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler(answer.message);
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deleteCombthruWithCombthruId:(NSString *)combthruId
               withCompletionHandler:(void(^)(void))completionHandler
                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id": combthruId};
    [self requestWithUrlString:[RKConstant deleteCombthruUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)createCombthuWithImage:(UIImage *)image
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
                   withCaption:(NSString *)caption
                    withStyles:(NSArray<RKStyle *> *)styles
              withTagedStylist:(NSString *)tagedStylist
             withFacebookToken:(NSString *)facebookToken
              withTwitterToken:(NSString *)twitterToken
             withTwitterSecret:(NSString *)twitterSecret
         withCompletionHandler:(void(^)(RKCombthru *combthru))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"file":  image,
                                                                                  @"latitude":  @(latitude),
                                                                                  @"longitude": @(longitude),
                                                                                  @"caption":   caption}];
    for (NSInteger i = 0; i < styles.count; i ++) {
    
        RKStyle *style  = [styles objectAtIndex:i];
        [params setObject:style.ident
                   forKey:[NSString stringWithFormat:@"styles[%ld]",
                           (long)i]];
    
    }
    if (tagedStylist) {
    
        [params setObject:tagedStylist
                   forKey:@"tag_stylist"];
    
    }
    if (facebookToken) {
    
        [params setObject:@1
                   forKey:@"share_to_facebook"];
        [params setObject:facebookToken
                   forKey:@"facebook_token"];
    
    }
    if (twitterToken &&
        twitterSecret) {
    
        [params setObject:@1
                    forKey:@"share_to_twitter"];
        [params setObject:twitterToken
                   forKey:@"twitter_token"];
        [params setObject:twitterSecret
                   forKey:@"twitter_secret"];
    
    }
    
    [self requestWithUrlString:[RKConstant createComthruUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKCombthru *combthru     = [[RKCombthru alloc]
                                           initWithDictionary:[answer.dataDict objectForKey:@"post"]
                                           error:&parseError];
               if (!parseError) {
               
                   completionHandler(combthru);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)createCombthruCommentWithCombthruId:(NSString *)combthruId
                                   withText:(NSString *)text
                      withCompletionHandler:(void(^)(RKCombthruComment *comment))completionHandler
                           withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"comb_id": combthruId,
                                @"text":    text};
    [self requestWithUrlString:[RKConstant addCombthruCommentUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKCombthruComment *comment   = [[RKCombthruComment alloc]
                                               initWithDictionary:[answer.dataDict objectForKey:@"comment"]
                                               error:&parseError];
               if (!parseError) {
               
                   completionHandler(comment);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
            
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getcombthruCommentsWithCombthruId:(NSString *)combthruId
                               withOffset:(NSInteger)offset
                    withCompletionHandler:(void(^)(NSArray<RKCombthruComment *> *comments))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"comb_id": combthruId,
                                @"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant combthruCommentsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKCombthruComment *> *comments   = [RKCombthruComment arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"comments"]
                                                                                                     error:&parseError];
               if (!parseError) {
               
                   completionHandler(comments);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deleteCombthruCommentWithCommentId:(NSString *)commentId
                     withCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"id":  commentId};
    [self requestWithUrlString:[RKConstant deleteCombthruCommentUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)combthruResetViewsWithCompletionHandler:(void(^)(void))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant combthruResetViewsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)combthruShareToChatWithCombthruId:(NSString *)combthruId
                               withChatId:(NSString *)chatId
                    withCompletionHandler:(void(^)(void))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"thread_id":   chatId,
                                @"comb_id":     combthruId};
    [self requestWithUrlString:[RKConstant combthruShareToChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

#pragma mark - User -

- (void)updateLocationWithLatitutde:(CGFloat)latitude
                      withLongitude:(CGFloat)longitude {

    NSDictionary *params    = @{@"latitude":    @(latitude),
                                @"longitude":   @(longitude)};
    [self requestWithUrlString:[RKConstant updateLocationUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPatch
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
//               NSLog(@"[Current location updated]");
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
//               NSLog(@"[Current location update error]: %@",
//                     answer.errorMessage);
           }];

}

#pragma mark - Circle -

- (void)startFollowWithUserId:(NSString *)userId
        withCompletionHandler:(void(^)(void))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": userId};
    [self requestWithUrlString:[RKConstant startFollowingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)stopFollowWithUserId:(NSString *)userId
       withCompletionHandler:(void(^)(void))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"user_id": userId};
    [self requestWithUrlString:[RKConstant stopFollowingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)getFollowingWithOffset:(NSInteger)offset
                    withUserId:(NSString *)userId
                     withQuery:(NSString *)query
         withCompletionHandler:(void(^)(RKFans *fans))completionHandler
                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"offset":    @(offset),
                                                                                  @"query":     query,}];
    if (userId) {
    
        [params setObject:userId
                   forKey:@"user_id"];
    
    }
    [self requestWithUrlString:[RKConstant getFollowingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKFans *fans = [[RKFans alloc]
                               initWithDictionary:answer.dataDict
                               error:&parseError];
               if (!parseError) {
               
                   completionHandler(fans);
               
               } else {
               
                   errorHandler(answer.errorMessage);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getFollowersWithOffset:(NSInteger)offset
                    withUserId:(NSString *)userId
                     withQuery:(NSString *)query
         withCompletionHandler:(void(^)(RKFans *fans))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"offset":    @(offset),
                                                                                  @"query":     query}];
    if (userId) {
        
        [params setObject:userId
                   forKey:@"user_id"];
        
    }
    [self requestWithUrlString:[RKConstant getFollowersUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKFans *fans = [[RKFans alloc]
                               initWithDictionary:answer.dataDict
                               error:&parseError];
               if (!parseError) {
                   
                   completionHandler(fans);
                   
               } else {
                   
                   errorHandler(answer.errorMessage);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

#pragma mark - Notifications -

- (void)notificationRegisterWithCompletionHandler:(void(^)(void))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSString *pushToken = [[FIRInstanceID instanceID]
                           token];
    if (!pushToken) {
    
        completionHandler();
        
        return;
    
    }
    
    NSDictionary *params    = @{@"device_id":   [[RKKeychainManager sharedManager]
                                                 deviceId],
                                @"push_token":  pushToken};
    [self requestWithUrlString:[RKConstant notificationRegisterUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Device registered]: %@",
                     answer.dataDict);
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               NSLog(@"[Device registration] error: %@",
                     answer.errorMessage);
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)notificationUnregisterWithCompletionHandler:(void(^)(void))completionHandler
                                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"device_id":   [[RKKeychainManager sharedManager]
                                                 deviceId]};
    [self requestWithUrlString:[RKConstant notificationUnregisterUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getNotificationsUnreadCountWithCompletionHandler:(void(^)(NSInteger unreadCount))completionHandler
                                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant notificationsUnreadCountUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSNumber *unreadNumber   = [answer.dataDict objectForKey:@"unread_count"];
               if (unreadNumber) {
               
                   [[NSUserDefaults standardUserDefaults]
                    setObject:unreadNumber
                    forKey:@"notifications_count"];
                   [[NSUserDefaults standardUserDefaults]
                    synchronize];
                   
                   completionHandler(unreadNumber.integerValue);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getNotificationsWithOffset:(NSInteger)offset
             withCompletionHandler:(void(^)(NSArray<RKNotification *> *notifications))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant notificationsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKNotification *> *notifications = [RKNotification arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"notifications"]
                                                                                                  error:&parseError];
               if (!parseError) {
               
                   completionHandler(notifications);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postReadNotificationsWithCompletionHandler:(void(^)(void))completionHandler
                                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant postReadNotificationsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               [[NSUserDefaults standardUserDefaults]
                setObject:@0
                forKey:@"notifications_count"];
               [[NSUserDefaults standardUserDefaults]
                synchronize];
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getNotificationSettingsWithCompletionHandler:(void(^)(NSArray<RKNotificationSetting *> *notificationSettings))completionHandler
                                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    [self requestWithUrlString:[RKConstant getNotificationSettingsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKNotificationSetting *> *settings   = [RKNotificationSetting arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"settings"]
                                                                                                             error:&parseError];
               if (!parseError) {
               
                   completionHandler(settings);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)updateNotificationSettigs:(NSArray<RKNotificationSetting *> *)notificationSettings
            withCompletionHandler:(void(^)(void))completionHandler
                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (RKNotificationSetting *setting in notificationSettings) {
        
        [params setObject:@(setting.value)
                   forKey:setting.ident];
        
    }
    [self requestWithUrlString:[RKConstant updateNotificationSettingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPut
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Privacy Settings -

- (void)getPrivacySettingsWithCompletionHandler:(void(^)(NSArray<RKNotificationSetting *> *settings))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    [self requestWithUrlString:[RKConstant getPrivacySettingsUrl]
             withAuthorization:YES
                    withParams:nil
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKNotificationSetting *> *settings   = [RKNotificationSetting arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"settings"]
                                                                                                             error:&parseError];
               if (!parseError) {
                   
                   completionHandler(settings);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)postPrivacySettingWithSettings:(NSArray<RKNotificationSetting *> *)settings
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (RKNotificationSetting *setting in settings) {
        
        [params setObject:@(setting.value)
                   forKey:setting.ident];
        
    }
    [self requestWithUrlString:[RKConstant postPrivacySettingUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPut
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

#pragma mark - Portfolio -

- (void)addPortfolioWitImage:(UIImage *)image
                withLatitude:(CGFloat)latitude
               withLongitude:(CGFloat)longitude
                 withCaption:(NSString *)caption
              withTagStylist:(NSString *)tagStylist
       withCompletionHandler:(void(^)(RKCombthru *portfolio))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"file":      image,
                                                                                  @"latitude":  @(latitude),
                                                                                  @"longitude": @(longitude)}];
    if (caption) {
        
        [params setObject:caption
                   forKey:@"caption"];
        
    }
    if (tagStylist) {
    
        [params setObject:tagStylist
                   forKey:@"tag_stylist"];
    
    }
    [self requestWithUrlString:[RKConstant addPortfolioUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKCombthru *portfolio    = [[RKCombthru alloc]
                                           initWithDictionary:[answer.dataDict objectForKey:@"post"]
                                           error:&parseError];
               if (!parseError) {
               
                   completionHandler(portfolio);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deletePortfolioWithPortfolioId:(NSString *)portfolioId
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  portfolioId};
    [self requestWithUrlString:[RKConstant deletePortfolioUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Blocklist -

- (void)addBlockWithUserId:(NSString *)userId
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": userId};
    [self requestWithUrlString:[RKConstant addBlockUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deleteBlockWithUserId:(NSString *)userId
        withCompletionHandler:(void(^)(void))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": userId};
    [self requestWithUrlString:[RKConstant deleteBlockUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)getBlockedListWithQuery:(NSString *)query
                     withOffset:(NSInteger)offset
          withCompletionHandler:(void(^)(NSArray<RKUser *> *users))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"query":   query,
                                @"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant blocklistUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKUser *> *users = [RKUser arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"users"]
                                                                          error:&parseError];
               if (!parseError) {
               
                   completionHandler(users);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Messages -

- (void)getChatsWithQuery:(NSString *)query
               withOffset:(NSInteger)offset
    withCompletionHandler:(void(^)(NSArray<RKChat *> *chats))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"query":   query,
                                @"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant getChatsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKChat *> *chats = [RKChat arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"threads"]
                                                                          error:&parseError];
               if (!parseError) {
               
                   completionHandler(chats);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)getChatWithChatId:(NSString *)chatId
    withCompletionHandler:(void(^)(RKChat *chat))completionHandler
         withErrorHandler:(void(^)(void))errorHandler {

    NSDictionary *params    = @{@"id":  chatId};
    [self requestWithUrlString:[RKConstant getChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKChat *chat = [[RKChat alloc]
                               initWithDictionary:[answer.dataDict objectForKey:@"thread"]
                               error:&parseError];
               if (!parseError) {
               
                   completionHandler(chat);
               
               } else {
               
                   errorHandler();
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler();
               
           }];

}

- (void)getMessagesWithChatId:(NSString *)chatId
                   withOffset:(NSInteger)offset
        withCompletionHandler:(void(^)(NSArray<RKMessage *> *messages))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"thread_id":   chatId,
                                @"offset":      @(offset)};
    [self requestWithUrlString:[RKConstant getChatMessagesUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKMessage *> *messages   = [RKMessage arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"messages"]
                                                                                     error:&parseError];
               if (!parseError) {
                   
                   completionHandler(messages);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postChatReadWithChatId:(NSString *)chatId
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"thread_id":   chatId};
    [self requestWithUrlString:[RKConstant postChatReadUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)createChatWithUserId:(NSString *)userId
       withCompletionHandler:(void(^)(RKChat *chat))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"user_id": userId};
    [self requestWithUrlString:[RKConstant createChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKChat *chat = [[RKChat alloc]
                               initWithDictionary:[answer.dataDict objectForKey:@"thread"]
                               error:&parseError];
               if (!parseError) {
                   
                   completionHandler(chat);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)deleteChatWithChatId:(NSString *)chatId
       withCompletionHandler:(void(^)(void))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"thread_id":   chatId};
    [self requestWithUrlString:[RKConstant deleteChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postMessageToChatWithChatId:(NSString *)chatId
                           withText:(NSString *)text
              withCompletionHandler:(void(^)(RKMessage *message))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"thread_id":   chatId,
                                @"message":     text};
    [self requestWithUrlString:[RKConstant postMessageToChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKMessage *message   = [[RKMessage alloc]
                                       initWithDictionary:[answer.dataDict objectForKey:@"message"]
                                       error:&parseError];
               if (!parseError) {
               
                   completionHandler(message);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postImageToChatWithChatId:(NSString *)chatId
                        withImage:(UIImage *)image
              withProgressHandler:(void(^)(CGFloat progress))progressHandler
            withCompletionhandler:(void(^)(RKMessage *message))completionHandler
                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"thread_id":   chatId,
                                @"file":        image};
    [self requestWithUrlString:[RKConstant postImageToChatUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
               
               progressHandler(progress);
               
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKMessage *message   = [[RKMessage alloc]
                                       initWithDictionary:[answer.dataDict objectForKey:@"message"]
                                       error:&parseError];
               if (!parseError) {
                   
                   completionHandler(message);
                   
               } else {
                   
                   errorHandler([RKConstant unknownErrorText]);
                   
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Announcements -

- (void)getAnnouncementsWithOffset:(NSInteger)offset
             withCompletionHandler:(void(^)(NSArray<RKAnnouncement *> *announcements))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"offset":  @(offset)};
    [self requestWithUrlString:[RKConstant getAnnouncementsUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseErrror;
               NSArray<RKAnnouncement *> *announcements = [RKAnnouncement arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"announcements"]
                                                                                                  error:&parseErrror];
               if (!parseErrror) {
               
                   completionHandler(announcements);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)postReadAnnouncementWithAnnouncementId:(NSString *)announcementId
                         withCompletionHandler:(void(^)(void))completionHandler
                              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  announcementId};
    [self requestWithUrlString:[RKConstant readAnnouncementUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

#pragma mark - Jobs -

- (void)getJobsWithPosted:(BOOL)posted
                withSaved:(BOOL)saved
              withApplied:(BOOL)applied
               withOffset:(NSInteger)offset
                withQuery:(NSString *)query
    withCompletionHandler:(void(^)(NSArray<RKJob *> *jobs))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSString *urlString = [RKConstant getAllJobsUrl];
    urlString           = posted ? [RKConstant getPostedJobsUrl] : urlString;
    urlString           = saved ? [RKConstant getSavedJobsUrl] : urlString;
    urlString           = applied ? [RKConstant getAppliedJobsUrl] : urlString;
    
    NSDictionary *params    = @{@"offset":  @(offset),
                                @"query":   query};
    [self requestWithUrlString:urlString
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodGet
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               NSArray<RKJob *> *jobs   = [RKJob arrayOfModelsFromDictionaries:[answer.dataDict objectForKey:@"jobs"]
                                                                         error:&parseError];
               if (!parseError) {
               
                   completionHandler(jobs);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)createJobWithTitle:(NSString *)title
                withDetail:(NSString *)detail
               withAddress:(NSString *)address
               withWebSite:(NSString *)website
             withStartDate:(NSDate *)startDate
                  withWage:(NSString *)wage
                 withEmail:(NSString *)email
                 withImage:(UIImage *)image
              withLatitude:(CGFloat)latitude
             withLongitude:(CGFloat)longitude
             withSalonName:(NSString *)salonName
               withBooking:(BOOL)booking
     withCompletionHandler:(void(^)(RKJob *job))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"title":           title,
                                @"details":         detail,
                                @"address":         address,
                                @"web_site":        website,
                                @"start_date":      [[RKUtilitiesManager sharedManager] stringFromDate:startDate
                                                                                      withLocaleString:nil
                                                                                    withTimeZoneString:@"UTC"
                                                                                            withFormat:@"yyyy-MM-dd"],
                                @"wage":            wage,
                                @"contact_email":   email,
                                @"cover":           image,
                                @"latitude":        @(latitude),
                                @"longitude":       @(longitude),
                                @"salon_name":      salonName,
                                @"is_booking":      booking ? @1 : @0
                                };
    [self requestWithUrlString:[RKConstant createJobUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               NSError *parseError;
               RKJob *job   = [[RKJob alloc]
                               initWithDictionary:[answer.dataDict objectForKey:@"job"]
                               error:&parseError];
               if (!parseError) {
               
                   completionHandler(job);
               
               } else {
               
                   errorHandler([RKConstant unknownErrorText]);
               
               }
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)saveJobWithJobId:(NSString *)jobId
                withSave:(BOOL)save
    witCompletionHandler:(void(^)(void))completionHandler
        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  jobId};
    [self requestWithUrlString:[RKConstant saveJobUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:save ? RKHTTPMethodPost : RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)applyJobWithJobId:(NSString *)jobId
                withApply:(BOOL)apply
    withCompletionHandler:(void(^)(void))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {

    NSDictionary *params    = @{@"id":  jobId};
    [self requestWithUrlString:[RKConstant applyJobUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:apply ? RKHTTPMethodPost : RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];

}

- (void)editJobWithJobId:(NSString *)jobId
               withTitle:(NSString *)title
             withDetails:(NSString *)details
             withAddress:(NSString *)address
             withWebSite:(NSString *)webSite
               withEmail:(NSString *)email
                withWage:(NSString *)wage
           withStartDate:(NSDate *)startDate
          withCoverImage:(UIImage *)coverImage
            withLatitude:(CGFloat)latitude
           withLongitude:(CGFloat)longitude
           withIsBooking:(BOOL)isBooking
           withSalonName:(NSString *)salonName
   withCompletionHandler:(void(^)(void))completionHandler
        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"id":            jobId,
                                                                                  @"title":         title,
                                                                                  @"details":       details,
                                                                                  @"address":       address,
                                                                                  @"web_site":      webSite,
                                                                                  @"contact_email": email,
                                                                                  @"wage":          wage,
                                                                                  @"start_date":    [[RKUtilitiesManager sharedManager]
                                                                                                     stringFromDate:startDate
                                                                                                     withFormat:@"yyyy-MM-dd"],
                                                                                  @"latitude":      @(latitude),
                                                                                  @"longitude":     @(longitude),
                                                                                  @"is_booking":    isBooking ? @1 : @0,
                                                                                  @"salon_name":    salonName
                                                                                  }];
    if (coverImage) {
        
        [params setObject:coverImage
                   forKey:@"cover"];
        
    }
    [self requestWithUrlString:[RKConstant editJobUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodPost
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

- (void)deleteJobWithJobId:(NSString *)jobId
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler {
    
    NSDictionary *params    = @{@"id":  jobId};
    [self requestWithUrlString:[RKConstant deleteJobUrl]
             withAuthorization:YES
                    withParams:params
                    withMethod:RKHTTPMethodDelete
           withProgressHandler:^(CGFloat progress) {
           } withCompletionHandler:^(RKApiAnswer *answer) {
               
               completionHandler();
               
           } withErrorHandler:^(RKApiAnswer *answer) {
               
               errorHandler(answer.errorMessage);
               
           }];
    
}

@end





























//
