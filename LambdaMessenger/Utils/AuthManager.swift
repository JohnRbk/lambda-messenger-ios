import Foundation
import Promises
import Firebase
// Note, AppSync also references an internal Promise class. So calls to google/Promises
// must be namespaced
//import AWSAppSync
import XCGLogger

public class AuthManager {

    private let log = XCGLogger.default

    public static func getIDToken(forceRefresh: Bool = false, user: Firebase.User) -> Promises.Promise<String> {

        let promise = Promises.Promise<String> { fulfill, reject in

            user.getIDTokenForcingRefresh(forceRefresh) { token, error in
                switch (token, error) {
                case let (nil, .some(error)):
                    reject(error)
                case let (.some(token), nil):
                    fulfill(token)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }
        }

        return promise

    }

    // Note: Firebase requires a call to getIDToken(refresh=true) after updating display name
    public static func updateDisplayName(_ displayName: String,
                                         forUser user: Firebase.User? = nil) -> Promises.Promise<Firebase.User> {

        let promise = Promises.Promise<Firebase.User> { fulfill, reject in

            let currentUser = user == nil ? Auth.auth().currentUser : user

            if let currentUser = currentUser {
                func callback(error: Error?) {
                    if let error = error { reject(error) } else { fulfill(currentUser) }
                }

                let change = currentUser.createProfileChangeRequest()
                change.displayName = displayName
                change.commitChanges(completion: callback)
            } else {
                reject(LambdaMessengerError.systemError)
            }
        }

        return promise

    }

    public static func createUser(withEmail email: String, password: String) -> Promises.Promise<Firebase.User> {

        let promise = Promises.Promise<Firebase.User> { fulfill, reject in

            func createUserHandler(result: AuthDataResult?, error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)):
                    fulfill(result.user)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            Auth.auth().createUser(withEmail: email, password: password, completion: createUserHandler)

        }

        return promise
    }

    static func signIn(withCredential credential: PhoneAuthCredential) -> Promises.Promise<Firebase.User> {
        let promise = Promises.Promise<Firebase.User> { fulfill, reject in

            func signInHandler(result: AuthDataResult?, error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)):
                    fulfill(result.user)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            Auth.auth().signInAndRetrieveData(with: credential, completion: signInHandler)

        }

        return promise
    }

    static func signIn(withEmail email: String, password: String) -> Promises.Promise<Firebase.User> {

        let promise = Promises.Promise<Firebase.User> { fulfill, reject in

            func signInHandler(result: AuthDataResult?, error: Error?) {
                switch (error, result) {
                case let (.some(error), nil):
                    reject(error)
                case let (nil, .some(result)):
                    fulfill(result.user)
                default:
                    reject(LambdaMessengerError.systemError)
                }
            }

            Auth.auth().signIn(withEmail: email, password: password, completion: signInHandler)

        }

        return promise
    }

}
