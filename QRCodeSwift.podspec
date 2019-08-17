Pod::Spec.new do |s|
  s.name             = 'QRCodeSwift'
  s.version          = '0.1.0'
  s.summary          = 'A short description of QRCodeSwift.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Tuluobo/QRCodeSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tuluobo' => 'tuluobo@vip.qq.com' }
  s.source           = { :git => 'https://github.com/Tuluobo/QRCodeSwift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Tuluobo'

  s.ios.deployment_target = '8.0'
  s.source_files = 'QRCodeSwift/Classes/*.swift'
  s.resource_bundles = {
    'QRCodeSwift' => ['QRCodeSwift/Resources/*']
  }
  
end
