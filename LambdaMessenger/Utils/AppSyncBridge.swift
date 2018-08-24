//
//  AppSyncBridge.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/22/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation

public protocol User {
    var displayName: String { get }
    var userId: String { get }
    var phoneNumber: String? { get }
    var email: String? { get }
}

public protocol Message {
    var message: String { get }
    var timestamp: String { get }
    var sender: String { get }
}

public struct UserMessage: Message {
    public var message: String    
    public var timestamp: String
    public var sender: String
}

public struct Conversation {
    let conversationId: String
    var messages: [Message] = []
    var users: [User] = []
    init(_ c: ConversationFields){
        self.conversationId = c.conversationId
        for m in c.messages {
            messages.append(m!)
        }
        for u in c.users {
            users.append(u!)
        }
    }
}

extension LookupUserByEmailQuery.Data.LookupUserByEmail: User {
    public var phoneNumber: String? {
        return nil
    }
}
extension LookupUserByPhoneNumberQuery.Data.LookupUserByPhoneNumber: User {
    public var email: String? {
        return nil
    }
}
extension NewMessageSubscription.Data.NewMessage: Message {}
extension ConversationFields.Message: Message {}
extension ConversationFields.User : User {}
extension RegisterUserWithEmailMutation.Data.RegisterUserWithEmail: User {
    public var phoneNumber: String? {
        return nil
    }
}
extension RegisterUserWithPhoneNumberMutation.Data.RegisterUserWithPhoneNumber: User {
    public var email: String? {
        return nil
    }
}
