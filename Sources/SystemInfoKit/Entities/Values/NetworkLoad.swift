struct NetworkLoad {
    var upload: Int64
    var download: Int64

    static let zero = NetworkLoad(upload: .zero, download: .zero)
}

func -(left: NetworkLoad, right: NetworkLoad) -> NetworkLoad {
    NetworkLoad(
        upload: left.upload - right.upload,
        download: left.download - right.download
    )
}

func +=(left: inout NetworkLoad, right: NetworkLoad) {
    left.upload += right.upload
    left.download += right.download
}

func !=(left: NetworkLoad, right: NetworkLoad) -> Bool {
    left.upload != right.upload || left.download != right.download
}
