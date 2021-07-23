//
//  ElmValidator.swift
//  SimeplCaller
//
//  Created by pzdev on 23/05/21.
//

import Foundation

class ElmValidator {
    
    static func isPasswordValid(_ password : String) -> Bool {
            
        //let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        //return passwordTest.evaluate(with: password)
        if (password.count >= 6) {
            return true
        } else {
            return false
        }
    }
    
}
