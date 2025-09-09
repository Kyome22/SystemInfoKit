//import Foundation
//import class Dispatch.DispatchSemaphore
//
//func async<R: Sendable>(await body: () async throws -> R) rethrows -> R {
//    try withoutActuallyEscaping(body) { body in
//        var result: Result<R, any Error>!
//        withoutActuallyEscaping({ result = $0 }) { setter in
//            let semaphore = DispatchSemaphore(value: 0)
//            Task<Void, Never> {
//                defer {
//                    semaphore.signal()
//                }
//                do {
//                    try await setter(.success(body()))
//                } catch {
//                    setter(.failure(error))
//                }
//            }
//            semaphore.wait()
//        }
//        return try result.get()
//    }
//}
