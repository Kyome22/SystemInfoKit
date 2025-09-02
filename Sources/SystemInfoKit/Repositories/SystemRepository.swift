protocol SystemRepository: Sendable {
    init(_ systemInfoStateClient: SystemInfoStateClient)
    func update()
    func reset()
}
