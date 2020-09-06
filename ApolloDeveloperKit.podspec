Pod::Spec.new do |spec|
  spec.name = "ApolloDeveloperKit"
  spec.version = "0.14.1"
  spec.summary = "Visual debugger for Apollo iOS GraphQL client"
  spec.description = <<-DESC
                   ApolloDeveloperKit is an iOS library which works as a bridge between Apollo iOS client and Apollo Client Developer tools.
                   This library adds an ability to watch the sent queries or mutations simultaneously, and also has the feature to request arbitrary operations from embedded GraphiQL console.
                   DESC
  spec.homepage = "https://github.com/manicmaniac/ApolloDeveloperKit"
  spec.screenshots = "https://user-images.githubusercontent.com/1672393/92017937-6fcc7d00-ed8f-11ea-8611-baf3aef386cf.png"
  spec.documentation_url = "https://manicmaniac.github.io/ApolloDeveloperKit"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.authors = { "Ryosuke Ito" => "rito.0305@gmail.com" }
  spec.ios.deployment_target = '9.0'
  spec.osx.deployment_target = '10.10'
  spec.source = { :git => "https://github.com/manicmaniac/ApolloDeveloperKit.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/Classes/**/*.swift"
  spec.resource = "Sources/Assets"
  spec.cocoapods_version = '>= 1.7.0'
  spec.swift_versions = ['5.0', '5.1', '5.2']
  spec.dependency "Apollo", ">= 0.29.0", "< 0.33.0"
end
