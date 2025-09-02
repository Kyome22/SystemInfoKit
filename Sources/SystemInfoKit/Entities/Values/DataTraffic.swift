struct DataTraffic {
    var upload: Int64
    var download: Int64

    static let zero = DataTraffic(upload: .zero, download: .zero)
}

func -(left: DataTraffic, right: DataTraffic) -> DataTraffic {
    DataTraffic(
        upload: left.upload - right.upload,
        download: left.download - right.download
    )
}

func +=(left: inout DataTraffic, right: DataTraffic) {
    left.upload += right.upload
    left.download += right.download
}

func !=(left: DataTraffic, right: DataTraffic) -> Bool {
    left.upload != right.upload || left.download != right.download
}
