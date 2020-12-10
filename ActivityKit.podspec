Pod::Spec.new do |spec|
  spec.name      = "ActivityKit"
  spec.version   = "2.2"
  spec.summary   = "ActivityKit provides macOS system information."
  spec.description  = <<-DESC
    ActivityKit provides macOS system information.
    - CPU usage
    - Memory performance
    - Battery state
    - Disk capacity
    - Network connection
    This framework is written in Swift 5.
  DESC
  spec.homepage = "https://github.com/Kyome22/ActivityKit"
  spec.license  = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  spec.author             = { "Takuto Nakamura" => "kyomesuke@icloud.com" }
  spec.social_media_url   = "https://twitter.com/Kyomesuke"
  spec.platform = :osx
  spec.osx.deployment_target = "10.15"
  spec.source   = { :git => "https://github.com/Kyome22/ActivityKit.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/ActivityKit/*.swift"
  spec.swift_version = "5"
  spec.requires_arc = true
end
