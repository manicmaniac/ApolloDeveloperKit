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
  spec.source       = { :git => "https://github.com/manicmaniac/ApolloDeveloperKit.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/Classes/**/*.swift"
  spec.resource = "Sources/Assets"
  spec.dependency "Apollo", ">= 0.9.0"
end
