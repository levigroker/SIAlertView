Pod::Spec.new do |s|
  s.name     = 'SIAlertView'
  s.version  = '1.3'
  s.platform = :ios
  s.license  = 'MIT'
  s.summary  = 'An UIAlertView replacement.'
  s.homepage = 'https://github.com/levigroker/SIAlertView'
  s.author   = { 'Levi Brown' => 'levigroker@gmail.com' }
  s.source   = { :git => 'https://github.com/levigroker/SIAlertView.git',
                 :commit => '6c09d990bdd30ca17941851a14dc56ecb6ac3477' }
  s.description = 'An UIAlertView replacement with block syntax and fancy transition styles.'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.framework    = 'QuartzCore'
  s.source_files = 'SIAlertView/*.{h,m}'
end
