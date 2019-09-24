Pod::Spec.new do |spec|
  spec.name         = "ApolloDeveloperKit"
  spec.version      = "0.3.3"
  spec.summary      = "Visual debug your app, that is based on Apollo iOS"
  spec.description  = <<-DESC
                   Visual debug your app, that is based on Apollo iOS.
                   Apollo Client Devtools bridge for Apollo iOS.
                   DESC
  spec.homepage     = "https://github.com/manicmaniac/ApolloDeveloperKit"
  spec.screenshots  = "https://user-images.githubusercontent.com/1672393/59568132-81a20180-90b1-11e9-9207-b2070b26e790.png"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.authors             = { "Ryosuke Ito" => "rito.0305@gmail.com" }
  spec.platform     = :ios, "9.0"
  spec.swift_versions = "4.2", "5.0"
  spec.source       = { :git => "https://github.com/manicmaniac/ApolloDeveloperKit.git", :tag => "#{spec.version}" }
  spec.prepare_command = 'touch Sources/Classes/ApolloDebugServer.swift Sources/Classes/DebuggableNetworkTransport.swift'
  spec.source_files  = "Sources/Classes/**/*.swift", "Sources/Classes/ApolloDebugServer.swift", "Sources/Classes/DebuggableNetworkTransport.swift"
  spec.script_phase = {
    :name => "Generate Swift sources",
    :execution_position => :before_compile,
    :input_files => [
      '$(PODS_TARGET_SRCROOT)/Sources/Classes/ApolloDebugServer.swift.erb',
      '$(PODS_TARGET_SRCROOT)/Sources/Classes/DebuggableNetworkTransport.swift.erb'
    ],
    :output_files => [
      '$(PODS_TARGET_SRCROOT)/Sources/Classes/ApolloDebugServer.swift',
      '$(PODS_TARGET_SRCROOT)/Sources/Classes/DebuggableNetworkTransport.swift'
    ],
    :script => <<-EOS
      cd "$PODS_TARGET_SRCROOT"
      erb -T - "$SCRIPT_INPUT_FILE_0" >"$SCRIPT_OUTPUT_FILE_0"
      erb -T - "$SCRIPT_INPUT_FILE_1" >"$SCRIPT_OUTPUT_FILE_1"
    EOS
  }
  spec.preserve_paths = "Scripts/apollo_version.rb", "Sources/Classes/**/*.swift.erb"
  spec.resource = "Sources/Assets"
  spec.dependency "Apollo", ">= 0.9.0", "< 0.13.0"
end
