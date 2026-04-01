import Foundation
import Combine

// MARK: - StateStore
final class StateStore<State> {
    private let subject: CurrentValueSubject<State, Never>

    var value: State { subject.value }
    var publisher: ReadOnlyPublisher<State> { ReadOnlyPublisher(subject: subject) }

    init(_ initial: State) {
        subject = CurrentValueSubject(initial)
    }

    func update(_ transform: (inout State) -> Void) {
        var current = subject.value
        transform(&current)
        subject.send(current)
    }
}

// MARK: - ReadOnlyPublisher
final class ReadOnlyPublisher<State>: Publisher {
    typealias Output = State
    typealias Failure = Never

    fileprivate let subject: CurrentValueSubject<State, Never>

    var value: State { subject.value }

    fileprivate init(subject: CurrentValueSubject<State, Never>) {
        self.subject = subject
    }

    func receive<S: Subscriber>(subscriber: S) where S.Input == State, S.Failure == Never {
        subject.receive(subscriber: subscriber)
    }
}

// MARK: - NoEffect
enum NoEffect {}

// MARK: - Typealiases
typealias EffectSubject<E> = PassthroughSubject<E, Never>
typealias EffectPublisher<E> = AnyPublisher<E, Never>

// MARK: - ViewModel Protocol
protocol ViewModel: AnyObject {
    associatedtype State
    associatedtype Action
    associatedtype Effect

    var statePublisher: ReadOnlyPublisher<State> { get }
    var effectPublisher: EffectPublisher<Effect> { get }

    func send(_ action: Action)
}

extension ViewModel {
    var state: State { statePublisher.value }
}

extension ViewModel where Effect == NoEffect {
    var effectPublisher: EffectPublisher<NoEffect> { Empty().eraseToAnyPublisher() }
}
