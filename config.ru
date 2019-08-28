# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

#require ::File.expand_path('../config/environment', __FILE__)
#map ENV['RAILS_RELATIVE_URL_ROOT'] || '/bnpp' do
#  run Rails.application
#end

run Rails.application
