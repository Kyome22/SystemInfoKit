protocol SystemRepository: Sendable {
    init(_ stateClient: StateClient)
    func update()
    func reset()
}
