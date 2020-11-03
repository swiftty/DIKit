import Foundation

extension DI {
    @propertyWrapper
    public struct Inject<Value> {
        @usableFromInline
        let storage: Storage

        public init() {
            storage = ValueStorage()
        }

        public init<Root>(_ root: Root.Type) {
            storage = RootValueStorage(root: root, value: Value.self)
        }

        public init<Root>(_ keyPath: KeyPath<Root, Value>) {
            storage = KeyPathStorage(keyPath: keyPath)
        }

        @inlinable
        public var wrappedValue: Value { storage.value }

        public func resolve() {
            storage.resolve()
        }

        @usableFromInline
        class Storage {
            @usableFromInline
            lazy var value: Value = resolvedValue
            @usableFromInline
            var resolvedValue: Value { fatalError() }
            @usableFromInline
            var resolver: Resolver { DI.Resolver.shared }

            final func resolve() {
                value = resolvedValue
            }
        }
    }
}

// MARK: - storage -
final class ValueStorage<Value>: DI.Inject<Value>.Storage {
    @usableFromInline
    override var resolvedValue: Value {
        resolver.resolve()!
    }
}

final class RootValueStorage<Root, Value>: DI.Inject<Value>.Storage {
    private let key: Pair

    @usableFromInline
    override var resolvedValue: Value {
        resolver.resolve(key)!
    }

    init(root: Root.Type, value: Value.Type) {
        key = Pair(root: root, value: value)
    }
}

final class KeyPathStorage<Value>: DI.Inject<Value>.Storage {
    private let keyPath: AnyKeyPath

    @usableFromInline
    override var resolvedValue: Value {
        resolver.resolve(keyPath)!
    }

    init<Target>(keyPath: KeyPath<Target, Value>) {
        self.keyPath = keyPath
    }
}
