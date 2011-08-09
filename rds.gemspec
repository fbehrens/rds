lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'rds/version'
Gem::Specification.new do |s|
  s.name        = 'rds'
  s.version     = Rds::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Frank Behrens']
  s.email       = ['fbehrens@gmail.com']
  s.homepage    = 'http://github.com/fbehrens/rds'
  s.summary     = 'Just another redis libary'
  s.description = 'not available'
  s.required_rubygems_version = '>= 1.3.6'
  
  s.add_dependency 'redis'
  s.add_dependency 'activesupport', '~>3.0.0'
  s.add_dependency 'i18n'
  s.add_dependency 'ruby-oci8','~>2.0.0'
  
  s.add_development_dependency 'rspec','2.6.0'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  
  s.files         = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
