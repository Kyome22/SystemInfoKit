import Foundation

extension Double {
    var round2dp: Double {
        (10.0 * self).rounded() / 10.0
    }
}
