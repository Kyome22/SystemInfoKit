//
//  File.swift
//
//
//  Created by ky0me22 on 2022/02/21.
//

import Foundation

extension Double {
    var round2dp: Double {
        return (10.0 * self).rounded() / 10.0
    }
}
