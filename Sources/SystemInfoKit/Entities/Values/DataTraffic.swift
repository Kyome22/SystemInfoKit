struct DataTraffic: Equatable {
    var upload: Double
    var download: Double

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
