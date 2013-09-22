require 'sinatra'
require 'sequel'
require 'date'

DB = Sequel.connect ENV['DATABASE_URL']
class App < Sinatra::Application
  before do
    unless DISABLE_AUTH
      halt(403) unless request.env['bouncer.email']
    end
  end

  helpers do
    def h(str)
      ERB::Util.html_escape(str)
    end
  end

  get '/' do
    erb :index
  end

  post '/guest' do
    params.inspect
    guest = params.select {|(k,v)| %w(guest_name visiting_on lunch nda herokai_name notify_hipchat notify_gchat notify_sms notes).include? k }
    guest.reject! {|k| v = guest[k]; v.nil? || v.empty?}
    begin
      record = DB[:guests] << guest
    rescue => e
      return "Couldn't create guest\n#{e.message.split("\n").first}"
    end
    "thanks"
  end

  get "/guest" do
    redirect '/'
  end

  get "/list" do
    @overview = DB[<<-SQL].all
      select
        v::date as visiting_on,
        count(visiting_on) as total,
        count(case lunch when true then true end) as lunch
      from generate_series(now(), now() + '2 weeks'::interval, '1 day') as v
      left outer join guests on v::date = visiting_on::date
      group by 1
      order by 1 asc;
    SQL

    @day = params[:day] || Date.today.to_s
    @day_guests = DB['select * from guests where ?::date = visiting_on::date', @day].all

    erb :list
  end
end

__END__

@@ layout
<html>
<head>
  <title>heroku guests</title>
  <style>
    body { font-family: monospace; }
    label { display: inline-block; width: 9em;}
    td { border-right: 1px solid grey; padding: 0 1em; }
    td.last { border-right: 0 }
  </style>
</head>
<body>
<a href="/">new guest</a> | <a href='/list'>guest list</a>
<%= yield %>
</body>
</html>

@@ index
<h1>New Guest</h1>
<form action="/guest" method="post">
  <fieldset>
    <label>Guest's Name*</label> <input name='guest_name' required><br>
    <label>Visiting on*</label>  <input type='date' name='visiting_on' placeholder="<%=Date.today.to_s%>" required><br>
    <label>Lunch?</label>        <input type='checkbox' name='lunch'> (please give at least 2 days notice)<br>
    <label>NDA?</label>          <input type='checkbox' name='nda'>
  </fieldset>
  <fieldset>
   <label>Your Name*</label>     <input name='herokai_name' required><br>
   <label>Notify Hipchat</label> <input type='checkbox' name='notify_hipchat'><br>
   <label>Notify GChat</label>   <input type='checkbox' name='notify_gchat'><br>
   <label>Notify SMS</label>     <input type='phonenumber' name='notify_sms' placeholder="your number"><br>
  </fieldset>
  <fieldset>
    <label>notes:</label><br>
    <textarea name='notes'></textarea><br>
  </fieldset>
  <input type="submit">
</form>


@@ list
<h1>Overview</h1>
<% @overview.each do |day| %>
  <%= "<b><a href='?day=#{day[:visiting_on]}'>#{day[:visiting_on].strftime('%a %b %d')}</a>:</b> #{day[:total]} visiting (#{day[:lunch]} for lunch)" %>
  <br>
<% end %>

<h1><%=h @day %></h1>
<table>
<tr><th>guest</th><th>lunch/nda</th><th>for</th><th>notify</th></tr>
<% @day_guests.each do |g| %>
  <tr>
    <td><%=h g[:guest_name] %></td>
    <td> <%= "lunch" if g[:lunch] %> <%= "nda" if g[:nda] %></td>
    <td><%=h g[:herokai_name] %></td>
    <td class='last'>
      <%= "hipchat" if g[:notify_hipchat] %>
      <%= "gchat" if g[:notify_gchat] %>
      <%= "sms #{g[:notify_sms]}" if g[:notify_gchat] %>
    </td>
  </tr>
<% end %>
</table>


