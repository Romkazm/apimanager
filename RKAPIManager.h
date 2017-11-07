//
//  RKAPIManager.h
//  Bonnti-Restart
//
//  Created by Roman Kazmirchuk on 18.08.17.
//  Copyright © 2017 Roman Kazmirchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RKApiAnswer.h"
#import "RKMyUser.h"
#import "RKStylist.h"
#import "RKAddressSuggestion.h"
#import "RKEvent.h"
#import "RKStylistMyProfile.h"
#import "RKCombthru.h"
#import "RKStyle.h"
#import "RKNotification.h"
#import "RKNotificationSetting.h"
#import "RKChat.h"
#import "RKUserSuggestion.h"
#import "RKClientProfile.h"
#import "RKAnnouncement.h"
#import "RKJob.h"
#import "RKFans.h"

@interface RKAPIManager : NSObject

+ (id)sharedManager;

#pragma mark - Launch -

- (void)updateConstants;

#pragma mark - Authorization

- (void)signInWithUsername:(NSString *)username
              withPassword:(NSString *)password
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)signInWithFacebookToken:(NSString *)token
          withCompletionHandler:(void(^)(void))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)signInWithTwitterToken:(NSString *)token
             withTwitterSecret:(NSString *)secret
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)signUpWithUsername:(NSString *)username
              withPassword:(NSString *)password
             withFirstName:(NSString *)firstName
              withLastName:(NSString *)lastName
                 withEmail:(NSString *)email
           withAccountType:(NSString *)accountType
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)signUpWithFacebookToken:(NSString *)token
                withAccountType:(NSString *)accountType
          withCompletionHandler:(void(^)(void))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)signUpWithTwitterToken:(NSString *)token
                    withSecret:(NSString *)secret
               withAccountType:(NSString *)accountType
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)resetPasswordRequestCodeWithUsername:(NSString *)username
                       withCompletionHandler:(void(^)(void))completionHandler
                            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)resetPasswordChangeWithCode:(NSString *)code
                       withPassword:(NSString *)password
                withPasswordConfirm:(NSString *)passwordConfirm
              withCompletionHandler:(void(^)(void))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Stylists

- (void)getStylistsWithLatitude:(CGFloat)latitude
                  withLongitude:(CGFloat)longitude
                     withOffset:(NSInteger)offset
          withCompletionHandler:(void(^)(NSArray<RKStylist *> *stylists))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getStylistWithStylistId:(NSString *)stylistId
         withCompletionHandeler:(void(^)(RKStylist *stylist))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)searchStylistWithQuery:(NSString *)query
                  withDistance:(NSInteger)distance
                     withPrice:(CGFloat)price
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
           withCurrentLocation:(BOOL)currentLocation
                    withOffset:(NSInteger)offset
         withCompletionHandler:(void(^)(NSArray<RKStylist *> *stylists))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)searchStylistsSuggestionWithQuery:(NSString *)query
                    withCompletionHandler:(void(^)(NSArray<NSString *> *suggestions))completionHandler
                         withErrorHandler:(void(^)(void))errorHandler;

- (void)createStylistReviewWithStylistId:(NSString *)stylistId
                              withRating:(NSInteger)rating
                             withComment:(NSString *)comment
                   withCompletionHandler:(void(^)(RKReview *review))completionHandler
                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Client -

- (void)getMyClientProfileWithCompletionHandler:(void(^)(RKClientProfile *profile))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getClientProfileWithClientId:(NSString *)clientId
               withCompletionHandler:(void(^)(RKClientProfile *profile))completionHandler
                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getAllEventsWithOffset:(NSInteger)offset
         withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
              withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)getnearYouEventsWithOffset:(NSInteger)offset
                      withLatitude:(CGFloat)latitude
                     withLongitude:(CGFloat)longitude
             withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                  withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)getPostsEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)getGoingEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)getMaybeEventsWithOffset:(NSInteger)offset
           withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
                withErrorHandler:(void(^)(NSString * errorMessage))errorHandler;

- (void)searchEventsWithOffset:(NSInteger)offset
                     withQuery:(NSString *)query
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
                withSortByDate:(BOOL)sortByDate
                  withDistance:(CGFloat)distance
         withCompletionHandler:(void(^)(NSArray<RKEvent *> *events))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postEventGoingWithEventId:(NSString *)eventId
                        withGoing:(BOOL)going;

- (void)postEventMaybeWithEventId:(NSString *)eventId
                        withMaybe:(BOOL)maybe;

- (void)postReportWithEventId:(NSString *)eventId
                   withReason:(NSString *)reason
        withCompletionHandler:(void(^)(NSString *message))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteEventWithEventId:(NSString *)eventId
         withCompletionHandler:(void(^)(NSString *message))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Services -

- (void)addressSuggestionsWithQuery:(NSString *)query
              withCompletionHandler:(void(^)(NSArray<RKAddressSuggestion *> *addressSuggestions))completionhandler
                   withErrorHandler:(void(^)(void))errorHandler;

- (void)usernameSuggestionsWithQuery:(NSString *)query
               withCompletionHandler:(void(^)(NSArray<RKUserSuggestion *> *suggestions))completionHandler
                    withErrorHandler:(void(^)(void))errorHandler;

#pragma mark - Settings -

- (void)getStylistMyProfileWithCompletionHandler:(void(^)(RKStylistMyProfile *myProfile))completionHandler
                                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
                        withErrorHandlerl:(void(^)(NSString *errorMessage))errorHandler;

- (void)updateStylistCoverPhotoWithImage:(UIImage *)image
                   withCompletionHandler:(void(^)(void))completionHandler
                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)updateStylistProfilePhotoWithImage:(UIImage *)image
                     withCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)addStylistServiceWithTitle:(NSString *)title
                         withPrice:(CGFloat)price
                      withDuration:(NSInteger)duration
             withCompletionHandler:(void(^)(void))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)updateStylistServiceWithServiceId:(NSString *)serviceId
                                withTitle:(NSString *)title
                                withPrice:(CGFloat)price
                             withDuration:(NSInteger)duration
                    withCompletionHandler:(void(^)(void))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteStylistServiceWithServiceId:(NSString *)serviceId
                    withCompletionHandler:(void(^)(void))completionhandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)updateStylistHoursWithHours:(RKHours *)hours
              withCompletionHandler:(void(^)(void))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)changePasswordWithOldPassword:(NSString *)oldPassword
                      withNewPassword:(NSString *)password
                  withConfirmPassword:(NSString *)confirmPassword
                withCompletionHandler:(void(^)(void))completionHandler
                     withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postClientProfileWithFirstName:(NSString *)firstName
                          withLastName:(NSString *)lastName
                              withMale:(BOOL)male
                     withHairTypeIdent:(NSString *)hairTypeIdent
                         withBirthDate:(NSDate *)birthDate
                               withBio:(NSString *)bio
                      withProfileImage:(UIImage *)profileImage
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteStylistProfileImageWithCompletionHandler:(void(^)(void))completionHandler
                                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteStylistCoverImageWithCompletionHandler:(void(^)(void))completionHandler
                                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteClientProfileImageWithCompletionHandler:(void(^)(void))completionHandler
                                     withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteAccountWithCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Combthru -

- (void)getCombthrusWithOffset:(NSInteger)offset
                    withNearMe:(BOOL)nearMe
              withStylistsOnly:(BOOL)stylistsOnly
                  withLatitude:(CGFloat)latitude
                 withLongitude:(CGFloat)longitude
         withCompletionHandler:(void(^)(NSArray<RKCombthru *> *combthrus))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getCombthrusWithTags:(BOOL)tags
                   withPosts:(BOOL)posts
                   withSaves:(BOOL)saves
               withStylistId:(NSString *)stylistId
                  withOffset:(NSInteger)offset
       withCompletionHandler:(void(^)(NSArray<RKCombthru *> *combthrus))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postCombthruBookmarkWithIsBookmarked:(BOOL)isBookmarked
                              withCombthruId:(NSString *)combthruId
                       withCompletionHandler:(void(^)(void))completionHandler
                            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)likeCombthruWithCombthruId:(NSString *)combthruId;

- (void)dislikeCombthruWithCombthruId:(NSString *)combthruId;

- (void)reportCombthruWithReason:(NSString *)reason
                  withCombthruId:(NSString *)combthruId
           withCompletionHandler:(void(^)(NSString *message))completionHandler
                withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteCombthruWithCombthruId:(NSString *)combthruId
               withCompletionHandler:(void(^)(void))completionHandler
                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)createCombthruCommentWithCombthruId:(NSString *)combthruId
                                   withText:(NSString *)text
                      withCompletionHandler:(void(^)(RKCombthruComment *comment))completionHandler
                           withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getcombthruCommentsWithCombthruId:(NSString *)combthruId
                               withOffset:(NSInteger)offset
                    withCompletionHandler:(void(^)(NSArray<RKCombthruComment *> *comments))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteCombthruCommentWithCommentId:(NSString *)commentId
                     withCompletionHandler:(void(^)(void))completionHandler
                          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)combthruResetViewsWithCompletionHandler:(void(^)(void))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)combthruShareToChatWithCombthruId:(NSString *)combthruId
                               withChatId:(NSString *)chatId
                    withCompletionHandler:(void(^)(void))completionHandler
                         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - User -

- (void)updateLocationWithLatitutde:(CGFloat)latitude
                      withLongitude:(CGFloat)longitude;

#pragma mark - Circle -

- (void)startFollowWithUserId:(NSString *)userId
        withCompletionHandler:(void(^)(void))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)stopFollowWithUserId:(NSString *)userId
       withCompletionHandler:(void(^)(void))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getFollowingWithOffset:(NSInteger)offset
                    withUserId:(NSString *)userId
                     withQuery:(NSString *)query
         withCompletionHandler:(void(^)(RKFans *fans))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getFollowersWithOffset:(NSInteger)offset
                    withUserId:(NSString *)userId
                     withQuery:(NSString *)query
         withCompletionHandler:(void(^)(RKFans *fans))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Notifications -

- (void)notificationRegisterWithCompletionHandler:(void(^)(void))completionHandler
                                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)notificationUnregisterWithCompletionHandler:(void(^)(void))completionHandler
                                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getNotificationsUnreadCountWithCompletionHandler:(void(^)(NSInteger unreadCount))completionHandler
                                        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getNotificationsWithOffset:(NSInteger)offset
             withCompletionHandler:(void(^)(NSArray<RKNotification *> *notifications))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postReadNotificationsWithCompletionHandler:(void(^)(void))completionHandler
                                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getNotificationSettingsWithCompletionHandler:(void(^)(NSArray<RKNotificationSetting *> *notificationSettings))completionHandler
                                    withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)updateNotificationSettigs:(NSArray<RKNotificationSetting *> *)notificationSettings
            withCompletionHandler:(void(^)(void))completionHandler
                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Privacy Settings -

- (void)getPrivacySettingsWithCompletionHandler:(void(^)(NSArray<RKNotificationSetting *> *settings))completionHandler
                               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postPrivacySettingWithSettings:(NSArray<RKNotificationSetting *> *)settings
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Portfolio -

- (void)addPortfolioWitImage:(UIImage *)image
                withLatitude:(CGFloat)latitude
               withLongitude:(CGFloat)longitude
                 withCaption:(NSString *)caption
              withTagStylist:(NSString *)tagStylist
       withCompletionHandler:(void(^)(RKCombthru *portfolio))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deletePortfolioWithPortfolioId:(NSString *)portfolioId
                 withCompletionHandler:(void(^)(void))completionHandler
                      withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Blocklist -

- (void)addBlockWithUserId:(NSString *)userId
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteBlockWithUserId:(NSString *)userId
        withCompletionHandler:(void(^)(void))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getBlockedListWithQuery:(NSString *)query
                     withOffset:(NSInteger)offset
          withCompletionHandler:(void(^)(NSArray<RKUser *> *users))completionHandler
               withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Messages -

- (void)getChatsWithQuery:(NSString *)query
               withOffset:(NSInteger)offset
    withCompletionHandler:(void(^)(NSArray<RKChat *> *chats))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)getChatWithChatId:(NSString *)chatId
    withCompletionHandler:(void(^)(RKChat *chat))completionHandler
         withErrorHandler:(void(^)(void))errorHandler;

- (void)getMessagesWithChatId:(NSString *)chatId
                   withOffset:(NSInteger)offset
        withCompletionHandler:(void(^)(NSArray<RKMessage *> *messages))completionHandler
             withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postChatReadWithChatId:(NSString *)chatId
         withCompletionHandler:(void(^)(void))completionHandler
              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)createChatWithUserId:(NSString *)userId
       withCompletionHandler:(void(^)(RKChat *chat))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteChatWithChatId:(NSString *)chatId
       withCompletionHandler:(void(^)(void))completionHandler
            withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postMessageToChatWithChatId:(NSString *)chatId
                           withText:(NSString *)text
              withCompletionHandler:(void(^)(RKMessage *message))completionHandler
                   withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postImageToChatWithChatId:(NSString *)chatId
                        withImage:(UIImage *)image
              withProgressHandler:(void(^)(CGFloat progress))progressHandler
            withCompletionhandler:(void(^)(RKMessage *message))completionHandler
                 withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Announcements -

- (void)getAnnouncementsWithOffset:(NSInteger)offset
             withCompletionHandler:(void(^)(NSArray<RKAnnouncement *> *announcements))completionHandler
                  withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)postReadAnnouncementWithAnnouncementId:(NSString *)announcementId
                         withCompletionHandler:(void(^)(void))completionHandler
                              withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

#pragma mark - Jobs -

- (void)getJobsWithPosted:(BOOL)posted
                withSaved:(BOOL)saved
              withApplied:(BOOL)applied
               withOffset:(NSInteger)offset
                withQuery:(NSString *)query
    withCompletionHandler:(void(^)(NSArray<RKJob *> *jobs))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)saveJobWithJobId:(NSString *)jobId
                withSave:(BOOL)save
    witCompletionHandler:(void(^)(void))completionHandler
        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)applyJobWithJobId:(NSString *)jobId
                withApply:(BOOL)apply
    withCompletionHandler:(void(^)(void))completionHandler
         withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

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
        withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

- (void)deleteJobWithJobId:(NSString *)jobId
     withCompletionHandler:(void(^)(void))completionHandler
          withErrorHandler:(void(^)(NSString *errorMessage))errorHandler;

@end























//
