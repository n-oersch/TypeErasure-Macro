// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Creates a Type-Erased enum with each given Type being a case
/// 
/// Example:
/// ```
/// @TypeErasure([ModelA, ModelB])
/// protocol Proto {
///   var x: String { get set }
/// }
/// ```
/// adds the following enum:
/// ```
/// enum AnyProto {
///   case modelA(ModelA)
///   case modelB(ModelB)
///
///   var value: any Proto {
///     switch self {
///     case .modelA(let val as any Proto),
///          .modelB(let val as any Proto):
///       return val
///     }
///   }
///   var x: String {
///     self.value.x
///   }
/// }
/// ```
@attached(peer, names: prefixed(Any))
public macro TypeErasure(_ types: [Any.Type]) = #externalMacro(module: "TypeErasureMacros", type: "TypeErasureMacro")
