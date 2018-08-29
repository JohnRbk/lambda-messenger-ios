//
//  ApiManager.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/10/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import Promises
import Firebase
// Note, AppSync also references an internal Promise class. So calls to google/Promises
// must be namespaced
//import AWSAppSync
import XCGLogger
import UIKit
import AWSCore

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

public class OpenIdAuthProvider: AWSOIDCAuthProvider {
    let log = XCGLogger.default
    public func getLatestAuthToken(_ callback: @escaping (String) -> Void) {
        
        if let u = Auth.auth().currentUser {
            AuthManager.getIDToken(user: u).then { t in
                callback(t)
            }
        } else {
            // Probably want to diplay a message to the user asking them
            // to sign out and log back in
            log.error("Unable to get auth token")
            callback("")
        }
    }
}

public class ApiManager {

    private let log = XCGLogger.default
    private var client: AWSAppSyncClient?
    private let provider = OpenIdAuthProvider()

    public static let `default` = ApiManager()

    private init() {
        let url = URL(string: "https://nyloqsxggnetpjbnhv62x5tyh4.appsync-api.us-east-1.amazonaws.com/graphql")!
        do {
            let config = try AWSAppSyncClientConfiguration(url: url,
                                                           serviceRegion: AWSRegionType.USEast1,
                                                           oidcAuthProvider: self.provider)

            self.client = try AWSAppSyncClient(appSyncConfig: config)
        } catch (let error) {
            fatalError("Unable to configure client \(error.localizedDescription)")
        }
    }

    public typealias NewMessageSubscriptionPromise = Promises.Promise<AWSAppSyncSubscriptionWatcher<NewMessageSubscription>>

    public func subscribe(conversationId: String,
                   callback: @escaping (Message)->Void) -> NewMessageSubscriptionPromise {

        let newMessageSubscription = NewMessageSubscription(conversationId: conversationId)

        let promise = NewMessageSubscriptionPromise { fulfill, reject in

            func subcriptionHandler(result: GraphQLResult<NewMessageSubscription.Data>?,
                                    transaction: ApolloStore.ReadTransaction?, error: Error?) {

                switch (error, result) {
                case let (.some(error), nil):                    
                    self.log.error(error)
                    if let e = error as? AWSAppSyncSubscriptionError,
                        e.recoverySuggestion == "Restart subscription request." {
                        
                        let n = ConversationViewController.Events.restartSub.notification
                        NotificationCenter.default.post(name: n, object: conversationId)
                        
                        
                    }
                case let (nil, .some(result)) where result.errors != nil:
                    self.log.error(result.errors![0])
                case let (nil, .some(result)) where result.data?.newMessage?.fragments.messageFields != nil:
                    let m = Message(result.data!.newMessage!.fragments.messageFields)
                    callback(m)
                default:
                    self.log.error("Unable to process subscription message")
                }
            }

            if let subscription = try self.client?.subscribe(subscription: newMessageSubscription,
                                                             resultHandler: subcriptionHandler) {
                fulfill(subscription)
            } else {
                reject(LambdaMessengerError.systemError)
            }

        }

        return promise
    }

    public func postMessage(conversationId: String,
                            message: String) -> Promises.Promise<String> {

        let post = PostMessageMutation(conversationId: conversationId,
                                       message: message)

        let promise = Promises.Promise<String> { fulfill, reject in

            func postMessageHandler(result: GraphQLResult<PostMessageMutation.Data>?,
                                    error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.postMessage != nil:
                    fulfill(result.data!.postMessage.timestamp)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            self.log.info("Performing postMessage mutation")
            self.client?.perform(mutation: post, resultHandler: postMessageHandler)
        }

        return promise
    }

    public func getConversationHistory() -> Promises.Promise<[Conversation]> {
        
        let conversationHistory = GetConversationHistoryQuery()
        
        let promise = Promises.Promise<[Conversation]> { fulfill, reject in
            
            func historyHandler(result: GraphQLResult<GetConversationHistoryQuery.Data>?,
                                error: Error?) {
                
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.getConversationHistory != nil:
                    
                    var conversations: [Conversation] = []
                    for conversationData in result.data!.getConversationHistory! {
                        if let fields = conversationData?.fragments.conversationFields {
                            let c = Conversation(fields)
                            conversations.append(c)
                        }
                    }
                    fulfill(conversations)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing getConversationHistory query")
            self.client?.fetch(query: conversationHistory,
                               cachePolicy: .fetchIgnoringCacheData,
                               resultHandler: historyHandler)
            
        }
        
        return promise
        
    }

    public func updateUser(displayName: String, fcmToken: String) -> Promises.Promise<User> {
        
        let register = UpdateUserMutation(displayName: displayName, fcmToken: fcmToken)
        
        let promise = Promises.Promise<User> { fulfill, reject in
            
            func registerHandler(result: GraphQLResult<UpdateUserMutation.Data>?,
                                 error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.updateUser != nil:
                    fulfill(result.data!.updateUser)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing updateUser mutation")
            self.client?.perform(mutation: register, resultHandler: registerHandler)
            
        }
        
        return promise
        
    }
    
    public func registerUserWithPhoneNumber(fcmToken: String) -> Promises.Promise<User> {
        
        let register = RegisterUserWithPhoneNumberMutation(fcmToken: fcmToken)
        
        let promise = Promises.Promise<User> { fulfill, reject in
            
            func registerHandler(result: GraphQLResult<RegisterUserWithPhoneNumberMutation.Data>?,
                                 error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.registerUserWithPhoneNumber != nil:
                    fulfill(result.data!.registerUserWithPhoneNumber)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing registerUserWithPhoneNumber mutation")
            self.client?.perform(mutation: register, resultHandler: registerHandler)
            
        }
        
        return promise
        
    }
    
    public func registerUserWithEmail(fcmToken: String) -> Promises.Promise<User> {

        let register = RegisterUserWithEmailMutation(fcmToken: fcmToken)

        let promise = Promises.Promise<User> { fulfill, reject in

            func registerHandler(result: GraphQLResult<RegisterUserWithEmailMutation.Data>?,
                                 error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.registerUserWithEmail != nil:
                    fulfill(result.data!.registerUserWithEmail)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            self.log.info("Performing registerUserWithEmail mutation")
            self.client?.perform(mutation: register, resultHandler: registerHandler)

        }

        return promise

    }
    
    public func lookupUserByEmail(email: String) -> Promises.Promise<User>{
        let lookup = LookupUserByEmailQuery(email: email)
        
        let promise = Promises.Promise<User> { fulfill, reject in
            
            func emailLookupHandler(result: GraphQLResult<LookupUserByEmailQuery.Data>?,
                                    error: Error?)  {
                switch (error, result) {
                case let (.some(error), nil):
                    self.log.error(error)
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.lookupUserByEmail != nil:
                    fulfill(result.data!.lookupUserByEmail!)
                case let (nil, .some(result)) where result.data?.lookupUserByEmail == nil:
                    reject(LambdaMessengerError.userNotFoundError)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing lookupUserByEmail query")
            self.client?.fetch(query: lookup, resultHandler: emailLookupHandler)
        }
        
        return promise
        
    }
    
    public func getConversation(conversationId: String) -> Promises.Promise<Conversation>{
        let lookup = GetConversationQuery(conversationId: conversationId)
        
        let promise = Promises.Promise<Conversation> { fulfill, reject in
            
            func conversationHandler(result: GraphQLResult<GetConversationQuery.Data>?,
                                    error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result))
                    where result.data?.getConversation.fragments.conversationFields != nil:
                    
                    let c = Conversation(result.data!.getConversation.fragments.conversationFields)
                    fulfill(c)
                case let (nil, .some(result)) where result.data?.getConversation == nil:
                    reject(LambdaMessengerError.userNotFoundError)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing getConversation query")
            self.client?.fetch(query: lookup,
                               cachePolicy: .fetchIgnoringCacheData,
                               resultHandler: conversationHandler)
            
        }
        
        return promise
        
    }
    
    public func lookupUserByPhoneNumber(phoneNumber: String) -> Promises.Promise<User>{
        let lookup = LookupUserByPhoneNumberQuery(phoneNumber: phoneNumber)
        
        let promise = Promises.Promise<User> { fulfill, reject in
            
            func phoneLookupHandler(result: GraphQLResult<LookupUserByPhoneNumberQuery.Data>?,
                                             error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    self.log.error(error)
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result)) where result.data?.lookupUserByPhoneNumber != nil:
                    fulfill(result.data!.lookupUserByPhoneNumber!)
                case let (nil, .some(result)) where result.data?.lookupUserByPhoneNumber == nil:
                    reject(LambdaMessengerError.userNotFoundError)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
            
            self.log.info("Performing lookupUserByPhoneNumber query")
            self.client?.fetch(query: lookup,
                               cachePolicy: .fetchIgnoringCacheData,
                               resultHandler: phoneLookupHandler)
            
        }
        
        return promise
        
    }

    public func initiateConversation(others: [String]) -> Promises.Promise<String> {

        let initiate = InitiateConversationMutation(others: others)

        let promise = Promises.Promise<String> { fulfill, reject in

            func initiateConversationHandler(result: GraphQLResult<InitiateConversationMutation.Data>?,
                                             error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)) where result.errors != nil:
                    reject(result.errors![0])
                case let (nil, .some(result))
                    where result.data?.initiateConversation != nil:
                    fulfill(result.data!.initiateConversation) // ConversationID
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            self.log.info("Performing initiateConversation query")
            self.client?.perform(mutation: initiate, resultHandler: initiateConversationHandler)

        }

        return promise

    }

}
