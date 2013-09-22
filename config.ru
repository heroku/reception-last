require 'heroku/bouncer'
require './web.rb'

DISABLE_AUTH = ENV['WOAH_DISABLE_AUTH_OMG']

unless DISABLE_AUTH
  use Heroku::Bouncer, expose_token: true, herokai_only: true
end
run App
