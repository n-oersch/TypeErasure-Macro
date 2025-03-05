# TypeErasure-Macro
A Swift Macro, that creates a Type Erasure Enum on a Protocol

---

Creates a TypeErased `Any<Protocol>` enum with cases for all given types and passed-through functions and members of the Protocol.
 
The given Types need to implement this protocol!

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
   // given Types conforming to Proto
   case modelA(ModelA)
   case modelB(ModelB)

   // underlying value as protocol
   var value: any Proto {
     switch self {
     case .modelA(let val as any Proto),
          .modelB(let val as any Proto):
       return val
     }
   }
   
   // all members of the protocol passed through
   var x: String {
     self.value.x
   }
 }
 ```