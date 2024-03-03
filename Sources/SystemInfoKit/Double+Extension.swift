import Foundation

extension Double {
    var round2dp: Double {
        return (10.0 * self).rounded() / 10.0
    }
}
