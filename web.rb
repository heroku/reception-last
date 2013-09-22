require 'sinatra'
require 'sequel'

DB = Sequel.connect ENV['DATABASE_URL']
class App < Sinatra::Application
  before do
#    halt(403) unless request.env['bouncer.email']
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
  </style>
</head>
<body>
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
  <%= "<b>#{day[:visiting_on].strftime('%a %b %d')}:</b> #{day[:total]} visiting (#{day[:lunch]} for lunch)" %>
  <br>
<% end %>


