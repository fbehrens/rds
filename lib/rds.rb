require 'redis'
require 'active_support/all'
#require 'active_support/core_ext/string/inflections'
#require 'active_support/core_ext/string/strip'
#require 'active_support/core_ext/array/wrap'
#require 'active_support/core_ext/time/conversions'
#require 'active_support/core_ext/module/delegation.rb'

%w(base key model scope index kernel).each do |f| 
  require "rds/#{f}"
end
