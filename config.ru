require 'bundler'
Bundler.require

require './web.rb'

DISABLE_AUTH = ENV['WOAH_DISABLE_AUTH_OMG']

map '/assets' do
  environment = Sprockets::Environment.new

  environment.append_path 'assets/images'
  environment.append_path 'assets/javascripts'
  environment.append_path 'assets/stylesheets'

  run environment
end


unless DISABLE_AUTH
  use Heroku::Bouncer, expose_token: true
end
run App
