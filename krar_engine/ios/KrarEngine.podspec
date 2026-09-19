Pod::Spec.new do |s|
  s.name             = 'KrarEngine'
  s.version          = '0.1.0'
  s.summary          = 'Karplus-Strong string engine for Krar & Begena Studio, built from Rust.'
  s.description      = 'The Rust krar_engine crate compiled for iOS. It renders to CoreAudio itself and is driven from Dart through dart:ffi.'
  s.homepage         = 'https://github.com/Mattathiasa/Krar'
  s.license          = { :type => 'MIT' }
  s.author           = 'Mattathias Abraham'
  s.source           = { :path => '.' }
  s.platform         = :ios, '15.0'

  # Build it first with ./build-xcframework.sh
  s.vendored_frameworks = 'KrarEngine.xcframework'
end
