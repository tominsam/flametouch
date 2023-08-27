import Foundation
import Combine

// this one from https://www.swiftbysundell.com/articles/creating-combine-compatible-versions-of-async-await-apis/

extension PassthroughSubject where Failure == Error {
    static func emittingValues<T: AsyncSequence>(from sequence: T) -> Self where T.Element == Output {
        let subject = Self()
        Task {
            do {
                for try await value in sequence {
                    subject.send(value)
                }
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        return subject
    }
}

// this one is the obvious extension of that

extension PassthroughSubject where Failure == Never {
    static func emittingValues(from sequence: AsyncStream<Output>) -> Self {
        let subject = Self()

        Task {
            for await value in sequence {
                subject.send(value)
            }

            subject.send(completion: .finished)
        }

        return subject
    }
}
