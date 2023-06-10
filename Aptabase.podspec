Pod::Spec.new do |s|
    s.name                      = 'Aptabase'
    s.version                   = '0.1.0'
    s.summary                   = 'Swift SDK for Aptabase: Open Source, Privacy-First and Simple Analytics for Mobile, Desktop and Web Apps'
    s.homepage                  = 'https://aptabase.com'
    s.license                   = { :type => 'MIT', :file => 'LICENSE' }
    s.author                    = { 'Guilherme Oenning' => 'goenning@aptabase.com' }
    s.source                    = { :git => 'https://github.com/aptabase/aptabase-swift.git', :tag => s.version.to_s }
    s.ios.deployment_target     = '13.0'
    s.osx.deployment_target     = "10.15"
    s.watchos.deployment_target = "6.0"
    s.tvos.deployment_target    = "13.0"
    s.swift_version             = '5.5'
    s.source_files              = 'Sources/Aptabase/**/*'
  end