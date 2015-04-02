require 'bundler'
Bundler.require
require 'rack/session/cookie'
require 'heroku/bouncer'

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
  use Rack::Session::Cookie, secret: ENV.fetch('SECRET'), key: "my_app_session"
  use Heroku::Bouncer,
    expose_token: true,
    oauth: { id: ENV.fetch('HEROKU_OAUTH_ID'), secret: ENV.fetch('HEROKU_OAUTH_SECRET') },
    secret: ENV.fetch("SECRET")
end
run App
