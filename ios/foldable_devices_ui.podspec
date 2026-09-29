Pod::Spec.new do |s|
  s.name             = 'foldable_devices_ui'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter package project.'
  s.description      = <<-DESC
A new Flutter package project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'foldable_devices_ui/Sources/foldable_devices_ui/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
