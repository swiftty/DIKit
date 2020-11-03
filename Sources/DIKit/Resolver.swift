import Foundation

public enum DI {}  // swiftlint:disable:this type_name

extension DI {
    public struct Resolver {
        @usableFromInline
        static var _shared: Resolver!  // swiftlint:disable:this identifier_name

        @inlinable
        public static var shared: Resolver {
            get { _shared }
            set { _shared = newValue}
        }

        @usableFromInline
        var factories: [AnyHashable: () -> Any] = [:]

        public static func call(_ modifier: (inout Resolver) -> Void) {
            var resolver = self.init()
            modifier(&resolver)
            shared = resolver
        }

        public init() {}

        public mutating func register<Value>(_ value: @autoclosure @escaping () -> Value,
                                             to type: Value.Type) {
            factories[ObjectIdentifier(type)] = value
        }

        public mutating func register<Root, Value>(_ value: @autoclosure @escaping () -> Value,
                                                   to pair: (Root.Type, Value.Type)) {
            factories[Pair(root: pair.0, value: pair.1)] = value
        }

        public mutating func register<Root, Value>(_ value: @autoclosure @escaping () -> Value,
                                                   to keyPath: KeyPath<Root, Value>) {
            factories[keyPath] = value
        }

        // MARK: - resolver -
        @inlinable
        func resolve<Value>(_ type: Value.Type = Value.self) -> Value? {
            let value = factories[ObjectIdentifier(type)]
            return value?() as? Value
        }

        @inlinable
        func resolve<Value>(_ pair: Pair) -> Value? {
            let value = factories[pair]
            return value?() as? Value ?? resolve(Value.self)
        }

        @inlinable
        func resolve<Value>(_ keyPath: AnyKeyPath) -> Value? {
            let value = factories[keyPath]
            return value?() as? Value ?? resolve(Pair(keyPath: keyPath))
        }
    }
}

@usableFromInline
struct Pair: Hashable {
    let rootKey: ObjectIdentifier
    let valueKey: ObjectIdentifier

    init<Root, Value>(root: Root.Type, value: Value.Type) {
        rootKey = .init(root)
        valueKey = .init(value)
    }

    @usableFromInline
    init(keyPath: AnyKeyPath) {
        rootKey = .init(type(of: keyPath).rootType)
        valueKey = .init(type(of: keyPath).valueType)
    }
}
