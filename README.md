# TypeErasure-Macro
A Swift Macro, that creates a Type Erasure Enum from a Protocol

---

Type Erasure Macro to attach to a protocol with the following functionality:
- creates `Any<ProtocolName>` enum with the given Types as cases for safely getting underlying type
- new enum conforms to the same protocols as the attached protocol
- adds all protocol members & functions to this Type-Erased Enum
- adds `value` member to get the value of the enum as Protocol-Type
- adds static `from` function to map from a conforming model to the Type Erased enum

## Usage:

After importing this Package via SPM you can attach the `@TypeErasure` macro to any Protocol and pass conforming types into it as an array to create cases for each type.

---
## Example:
 ```
 @TypeErasure([ModelA, ModelB])
 protocol Proto {
   var x: String { get set }
 }
 ```
 expands to the following Type-Erased Enum:
 ```
 enum AnyProto {
   /// given Types conforming to Proto
   case modelA(ModelA)
   case modelB(ModelB)

   /// underlying value as protocol
   var value: any Proto {
     switch self {
     case .modelA(let val as any Proto),
          .modelB(let val as any Proto):
       return val
     }
   }
   
   /// all members of the protocol passed through
   var x: String {
     self.value.x
   }
 }
 ```
