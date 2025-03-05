import TypeErasure

@TypeErasure([ModelA, ModelB])
protocol Proto: Equatable {
    var name: String { get set }
    func test(param: String) -> Bool
}
struct ModelA: Proto {
    func test(param: String) -> Bool {
        return true
    }
    var name = "ModelA"
    var x = 1
}
struct ModelB: Proto {
    func test(param: String) -> Bool {
        return false
    }
    var name = "ModelB"
    var x = "10"
}
