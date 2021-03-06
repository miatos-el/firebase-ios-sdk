// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/**
 * A `HTTPSCallableResult` contains the result of calling a `HTTPSCallable`.
 */
@objc(FIRHTTPSCallableResult)
open class HTTPSCallableResult: NSObject {
  /**
   * The data that was returned from the Callable HTTPS trigger.
   *
   * The data is in the form of native objects. For example, if your trigger returned an
   * array, this object would be an NSArray. If your trigger returned a JavaScript object with
   * keys and values, this object would be an NSDictionary.
   */
  @objc public let data: Any

  internal init(data: Any) {
    self.data = data
  }
}

/**
 * A `HTTPSCallable` is reference to a particular Callable HTTPS trigger in Cloud Functions.
 */
@objc(FIRHTTPSCallable)
open class HTTPSCallable: NSObject {
  // MARK: - Private Properties

  // The functions client to use for making calls.
  private let functions: Functions

  // The name of the http endpoint this reference refers to.
  private let name: String

  // MARK: - Public Properties

  /**
   * The timeout to use when calling the function. Defaults to 70 seconds.
   */
  @objc open var timeoutInterval: TimeInterval = 70

  internal init(functions: Functions, name: String) {
    self.functions = functions
    self.name = name
  }

  /**
   * Executes this Callable HTTPS trigger asynchronously.
   *
   * The data passed into the trigger can be any of the following types:
   * * NSNull
   * * NSString
   * * NSNumber
   * * NSArray<id>, where the contained objects are also one of these types.
   * * NSDictionary<NSString, id>, where the values are also one of these types.
   *
   * The request to the Cloud Functions backend made by this method automatically includes a
   * Firebase Installations ID token to identify the app instance. If a user is logged in with
   * Firebase Auth, an auth ID token for the user is also automatically included.
   *
   * Firebase Cloud Messaging sends data to the Firebase backend periodically to collect information
   * regarding the app instance. To stop this, see `Messaging.deleteData()`. It
   * resumes with a new FCM Token the next time you call this method.
   *
   * @param data Parameters to pass to the trigger.
   * @param completion The block to call when the HTTPS request has completed.
   */
  @objc(callWithObject:completion:) open func call(_ data: Any? = nil,
                                                   completion: @escaping (HTTPSCallableResult?,
                                                                          Error?) -> Void) {
    functions.callFunction(name: name,
                           withObject: data,
                           timeout: timeoutInterval) { result in
      switch result {
      case let .success(callableResult):
        completion(callableResult, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  /**
   * Executes this Callable HTTPS trigger asynchronously. This API should only be used from Objective C
   *
   * The request to the Cloud Functions backend made by this method automatically includes a
   * Firebase Installations ID token to identify the app instance. If a user is logged in with
   * Firebase Auth, an auth ID token for the user is also automatically included.
   *
   * Firebase Cloud Messaging sends data to the Firebase backend periodically to collect information
   * regarding the app instance. To stop this, see `Messaging.deleteData()`. It
   * resumes with a new FCM Token the next time you call this method.
   *
   * @param completion The block to call when the HTTPS request has completed.
   */
  @objc(callWithCompletion:) public func __call(completion: @escaping (HTTPSCallableResult?,
                                                                       Error?) -> Void) {
    call(nil, completion: completion)
  }

  #if compiler(>=5.5.2) && canImport(_Concurrency)
    /**
     * Executes this Callable HTTPS trigger asynchronously.
     *
     * The request to the Cloud Functions backend made by this method automatically includes a
     * FCM token to identify the app instance. If a user is logged in with Firebase
     * Auth, an auth ID token for the user is also automatically included.
     *
     * Firebase Cloud Messaging sends data to the Firebase backend periodically to collect information
     * regarding the app instance. To stop this, see `Messaging.deleteData()`. It
     * resumes with a new FCM Token the next time you call this method.
     *
     * @param data Parameters to pass to the trigger.
     * @returns The result of the call.
     */
    @available(iOS 13, tvOS 13, macOS 10.15, macCatalyst 13, watchOS 7, *)
    open func call(_ data: Any? = nil) async throws -> HTTPSCallableResult {
      return try await withCheckedThrowingContinuation { continuation in
        // TODO(bonus): Use task to handle and cancellation.
        self.call(data) { callableResult, error in
          if let callableResult = callableResult {
            continuation.resume(returning: callableResult)
          } else {
            continuation.resume(throwing: error!)
          }
        }
      }
    }
  #endif // compiler(>=5.5.2) && canImport(_Concurrency)
}
