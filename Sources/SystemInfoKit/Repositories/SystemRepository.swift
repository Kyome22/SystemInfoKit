protocol SystemRepository: Sendable {
    init(_ dependencies: Dependencies)
    func update()
    func reset()
}
