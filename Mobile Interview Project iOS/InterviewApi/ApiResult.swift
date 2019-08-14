//
//  ApiResult.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation

/**
 * Wrapper for the response returned from an imperfect endpoint.
 */
enum ApiResult<Value> {
    case success(Value)
    case failure
}

