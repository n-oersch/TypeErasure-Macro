import TypeErasure

@TypeErasure([ModelA, ModelB])
protocol Proto {
  var name: String { get set }
}
struct ModelA: Proto {
  var name = "ModelA"
  var x = 1
}
struct ModelB: Proto {
  var name = "ModelB"
  var x = "10"
}
