Pod::Spec.new do |spec|
  spec.name = "ApolloDeveloperKit"
  spec.version = "0.7.5"
  spec.summary = "Visual debugger for Apollo iOS GraphQL client"
  spec.description = <<-DESC
                   ApolloDeveloperKit is an iOS library which works as a bridge between Apollo iOS client and Apollo Client Developer tools.
                   This library adds an ability to watch the sent queries or mutations simultaneously, and also has the feature to request arbitrary operations from embedded GraphiQL console.
                   DESC
  spec.homepage = "https://github.com/manicmaniac/ApolloDeveloperKit"
  spec.screenshots = "https://user-images.githubusercontent.com/1672393/59568132-81a20180-90b1-11e9-9207-b2070b26e790.png"
  spec.documentation_url = "https://manicmaniac.github.com/ApolloDeveloperKit"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.authors = { "Ryosuke Ito" => "rito.0305@gmail.com" }
  spec.ios.deployment_target = '9.0'
  spec.osx.deployment_target = '10.10'
  spec.source = { :git => "https://github.com/manicmaniac/ApolloDeveloperKit.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/Classes/**/*.swift"
  spec.resource = "Sources/Assets"
  spec.dependency "Apollo", ">= 0.9.1", "< 0.22.0"
end
