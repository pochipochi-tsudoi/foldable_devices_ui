Pod::Spec.new do |s|
  s.name             = 'foldable_devices_ui'
  s.version          = '0.1.0'
  s.summary          = 'Adaptive Flutter UI widgets and controllers for foldable devices.'
  s.description      = <<-DESC
Adaptive Flutter UI widgets and controllers for foldable devices, including iPhone Duo SafeArea, native toolbar actions, vertical navigation, and hinge-angle split layouts.
                       DESC
  s.homepage         = 'https://github.com/pochipochi-tsudoi/foldable_devices_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'pochipochi-tsudoi' => 'https://github.com/pochipochi-tsudoi' }
  s.source           = { :path => '.' }
  s.source_files = 'foldable_devices_ui/Sources/foldable_devices_ui/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
