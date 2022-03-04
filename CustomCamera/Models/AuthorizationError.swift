//
//  AuthorizationError.swift
//  CustomCamera
//
//  Created by Zachary Meier on 3/4/22.
//

import Foundation

enum AuthorizationError: Error {
  case deniedAuthorization
  case restrictedAuthorization
  case unknownAuthorization
}

extension AuthorizationError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .deniedAuthorization:
      return "Access denied"
    case .restrictedAuthorization:
      return "Access restricted"
    case .unknownAuthorization:
      return "Unknown authorization status"
    }
  }
}

