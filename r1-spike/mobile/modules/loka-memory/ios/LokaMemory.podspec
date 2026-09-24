# A2 probe only: local module reporting OS-visible physical memory.
Pod::Spec.new do |s|
  s.name           = 'LokaMemory'
  s.version        = '0.0.0'
  s.summary        = 'A2 probe: OS-visible physical memory'
  s.license        = 'UNLICENSED'
  s.author         = 'lorecrafting'
  s.homepage       = 'https://github.com/lorecrafting/lokacore'
  s.platforms      = { :ios => '16.4' }
  s.swift_version  = '5.9'
  s.source         = { git: '' }
  s.static_framework = true
  s.dependency 'ExpoModulesCore'
  s.source_files = '**/*.swift'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
