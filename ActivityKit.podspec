Pod::Spec.new do |spec|
  spec.name      = "ActivityKit"
  spec.version   = "1.0"
  spec.summary   = "ActivityKit provides macOS system information."
  spec.description  = <<-DESC
    ActivityKit provides macOS system information.
    - CPU usage
    - Memory performance
    - Disk capacity
    - Network connection
    This framework is written in Swift 5.
  DESC
  spec.homepage = "https://github.com/Kyome22/ActivityKit"
  spec.license  = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  spec.author             = { "Takuto Nakamura" => "kyomesuke@icloud.com" }
  spec.social_media_url   = "https://twitter.com/Kyomesuke"
  spec.platform = :osx
  spec.osx.deployment_target = "10.14"
  spec.source   = { :git => "https://github.com/Kyome22/ActivityKit.git", :tag => "#{spec.version}" }
  spec.source_files  = "ActivityKit/*.{h,swift}"
  spec.swift_version = "5"
  spec.frameworks = "Darwin", "SystemConfiguration"
  spec.requires_arc = true
end
