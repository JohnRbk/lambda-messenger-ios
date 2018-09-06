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

public struct Message {
    var message: String
    var timestamp: String
    var sender: User
    var conversationId: String
    init(_ m: MessageFields) {
        self.message = m.message
        self.sender = m.sender
        self.timestamp = m.timestamp
        self.conversationId = m.conversationId
    }
    init(_ m: ConversationFields.Message) {
        self.message = m.message
        self.sender = m.sender
        self.timestamp = m.timestamp
        self.conversationId = m.conversationId
    }
    init(_ m: NewMessageSubscription.Data.NewMessage) {
        self.message = m.message
        self.sender = m.sender
        self.timestamp = m.timestamp
        self.conversationId = m.conversationId
    }
}

public struct Conversation {
    let conversationId: String
    var messages: [Message] = []
    var users: [User] = []
    init(_ c: ConversationFields) {
        self.conversationId = c.conversationId
        for m in c.messages {

            messages.append(Message(m))
        }
        for u in c.users {
            users.append(u)
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

extension MessageFields.Sender: User {
    public var phoneNumber: String? {
        return nil
    }

    public var email: String? {
        return nil
    }
}

extension NewMessageSubscription.Data.NewMessage.Sender: User {
    public var phoneNumber: String? {
        return nil
    }

    public var email: String? {
        return nil
    }
}
extension UpdateUserMutation.Data.UpdateUser: User {}
extension ConversationFields.User: User {}
extension ConversationFields.Message.Sender: User {
    public var phoneNumber: String? {
        return nil
    }

    public var email: String? {
        return nil
    }
}

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
