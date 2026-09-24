# A2 local module: OS-visible physical memory, evidence files and process death.
Pod::Spec.new do |s|
  s.name           = 'LokaMemory'
  s.version        = '0.0.0'
  s.summary        = 'A2: memory probe, evidence files, process death'
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
