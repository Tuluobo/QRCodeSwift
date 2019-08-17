Pod::Spec.new do |s|
  s.name             = 'QRCodeSwift'
  s.version          = '0.1.1'
  s.summary          = 'A swift QRCode scanning framework.'
  s.description      = <<-DESC
  A Swifty QRCode framework of SGQRCode.
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
  s.swift_versions = ['4.0', '4.2', '5.0']

end
