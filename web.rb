require 'sinatra'
require 'sequel'
require 'date'
Sequel.extension(:core_extensions, :pg_range, :pg_range_ops)

DB = Sequel.connect ENV['DATABASE_URL']
class App < Sinatra::Application
  before do
    unless DISABLE_AUTH
      email = request.env['bouncer.email']
      halt(403) unless email && email =~ /@(heroku|salesforce|exacttarget)\.com\z/
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

  FIELDS = %w(guest_name lunch salesforce herokai_name notify_hipchat notify_gchat notify_sms notes)
  def guest_hash_from_params(params)
    guest = {}
    FIELDS.each {|field| guest[field] = params[field] }

    v_on = params['visiting_on']
    v_until = params['visiting_until']
    v_until = v_on if v_until.nil? || v_until.empty?
    guest['visiting_range'] = "[#{v_on}, #{v_until}]"

    guest
  end

  get "/guests" do
    redirect '/'
  end

  get "/guests/:id" do |id|
    begin
      @guest = DB[:guests].where(id: id).first
      @guest[:visiting_on] = @guest[:visiting_range].begin
      @guest[:visiting_until] = @guest[:visiting_range].end - 1 # dateranges come out of the database as [), but we store with []

      @checkins = DB[:checkins].where(guest_id: id)
    rescue
     halt(404)
    end
    halt(404, erb('not found')) unless @guest
    erb :editguest
  end

  post '/guests' do
    begin
      params['guest_names'].reject{|g| g.empty?}.each do |guest_name|
        params['guest_name'] = guest_name
        DB[:guests] << guest_hash_from_params(params)
      end
    rescue => e
      return erb "Couldn't create guest<br><pre>#{h e.message.split("\n").first}</pre>"
    end
    erb "thanks"
  end

  put "/guests/:id" do |id|
    guest = guest_hash_from_params(params)
    begin
      DB[:guests].where(id: id).update(guest)
    rescue => e
      return erb "Couldn't create guest <br><pre>#{h e.message.split("\n").first}</pre>"
    end
    erb "Updated"
  end

  post "/guests/:id/check_in" do |id|
    begin
      DB[:checkins] << {guest_id: id}
    rescue => e
      return erb "Couldn't check in guest <br><pre>#{h e.message.split("\n").first}</pre>"
    end
    redirect '/list'
  end

  delete "/guests/:gid/checkins/:id" do |gid,id|
    begin
      p DB[:checkins].where(id: id, guest_id: gid).delete
    rescue => e
      return erb "Couldn't remove check in <br><pre>#{h e.message.split("\n").first}</pre>"
    end
    redirect "/guests/#{gid}"
  end

  delete "/guests/:id" do |id|
    p DB[:guests].where(id: id).delete
    erb "Deleted"
  end

  get "/list" do
    @overview = DB[<<-SQL].all
      select
        v::date as visiting_on,
        count(visiting_range) as total,
        count(nullif(lunch, false)) as lunch
      from generate_series(
           now() AT TIME ZONE 'America/Los_Angeles',
           now() + '2 weeks'::interval, '1 day') as v
      left outer join guests on v::date <@ visiting_range
      group by 1
      order by 1 asc;
    SQL

    @day = params[:day] || Sequel.lit("(now() AT TIME ZONE 'America/Los_Angeles')")
    @day_guests = DB[<<-SQL, @day, @day].all
      select g.*, c.created_at as arrived_at
      from guests g
      left join checkins c on g.id=c.guest_id and c.created_at::date = ?::date
      where ?::date <@ visiting_range
      order by (c.created_at is not null), guest_name ;
      SQL

    erb :list
  end

  get "/stats" do
    @stats = DB[<<-SQL].all
with counts_by_day as (
    select
    v::date as visiting_on,
      count(visiting_range) as total,
      count(nullif(lunch, false)) as lunch,
      count(checkins.id) as checkins,
      count(nullif(lunch and checkins.id is not null, false) ) as checkinslunch
    from generate_series(
      '2013-09-01',
      date_trunc('month', now()) + '3 months - 1 day'::interval,
      '1 day') as v
    left outer join guests on v::date <@ visiting_range
    left outer join checkins on date_trunc('day', v::date) = date_trunc('day', checkins.created_at) and guests.id=checkins.guest_id
    where extract(isodow from v) < 6
    group by 1
  )
  select
    to_char(date_trunc('month', visiting_on), 'Month YYYY') as month,
    sum(total) as total,
    sum(lunch) as lunch,
    sum(checkins) as checkins,
    sum(checkinslunch) as checkinslunch
  from counts_by_day
  group by date_trunc('month', visiting_on)
  order by date_trunc('month', visiting_on) asc;
    SQL
    erb :stats
  end
end
