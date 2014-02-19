require 'sinatra'
require 'sequel'
require 'date'

DB = Sequel.connect ENV['DATABASE_URL']
class App < Sinatra::Application
  before do
    unless DISABLE_AUTH
      halt(403) unless request.env['bouncer.email']
    end

    proto = request.env["HTTP_X_FORWARDED_PROTO"]
    host  = request.env["HTTP_HOST"]
    uri   = request.env["REQUEST_URI"]
    if settings.production? && (proto != "https" || host != "reception.heroku.com")
      redirect "https://reception.heroku.com#{uri}"
    end
  end

  helpers do
    def h(str)
      ERB::Util.html_escape(str)
    end

    def name_value(attr, type=nil)
      name_part  = %Q(name="#{attr}" )
      value_part = if @guest
        case type
        when :checkbox
          "checked" if @guest[attr]
        when :date
          "value='#{@guest[attr].to_date}'" if @guest[attr]
        else
          "value='#{h @guest[attr]}'"
        end
      end
      [name_part, value_part].join
    end
  end

  get '/' do
    erb :index
  end

  FIELDS = %w(guest_name visiting_on lunch nda herokai_name notify_hipchat notify_gchat notify_sms notes)
  def guest_hash_from_params(params)
    guest = {}
    FIELDS.each {|field| guest[field] = params[field] }
    guest
  end

  post '/guests' do
    guest = guest_hash_from_params(params)
    begin
      record = DB[:guests] << guest
      p record
    rescue => e
      return erb "Couldn't create guest\n#{h e.message.split("\n").first}"
    end
    erb "thanks"
  end

  get "/guests" do
    redirect '/'
  end

  get "/guests/:id" do |id|
    begin
      @guest = DB[:guests].where(id: id).first
    rescue
     halt(404)
    end
    halt(404, erb('not found')) unless @guest
    erb :editguest
  end

  put "/guests/:id" do |id|
    guest = guest_hash_from_params(params)
    p DB[:guests].where(id: id).update(guest)
    erb "Updated"
  end

  delete "/guests/:id" do |id|
    p DB[:guests].where(id: id).delete
    erb "Deleted"
  end

  get "/list" do
    @overview = DB[<<-SQL].all
      select
        v::date as visiting_on,
        count(visiting_on) as total,
        count(nullif(lunch, false)) as lunch
      from generate_series(
           now() AT TIME ZONE 'America/Los_Angeles',
           now() + '2 weeks'::interval, '1 day') as v
      left outer join guests on v::date = visiting_on::date
      group by 1
      order by 1 asc;
    SQL

    @day = params[:day] || Date.today.to_s
    @day_guests = DB['select * from guests where ?::date = visiting_on::date', @day].all

    erb :list
  end
end

