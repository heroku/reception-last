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

  post '/guest' do
    guest = guest_hash_from_params(params)
    begin
      record = DB[:guests] << guest
      p record
    rescue => e
      return erb "Couldn't create guest\n#{h e.message.split("\n").first}"
    end
    erb "thanks"
  end

  get "/guest" do
    redirect '/'
  end

  get "/guest/:id" do |id|
    begin
      @guest = DB[:guests].where(id: id).first
    rescue
     halt(404)
    end
    halt(404, erb('not found')) unless @guest
    erb :editguest
  end

  put "/guesb/:id" do |id|
    guest = guest_hash_from_params(params)
    p DB[:guests].where(id: id).update(guest)
    erb "Updated"
  end

  delete "/guest/:id" do |id|
    p DB[:guests].where(id: id).delete
    erb "Deleted"
  end

  get "/list" do
    @overview = DB[<<-SQL].all
      select
        v::date as visiting_on,
        count(visiting_on) as total,
        count(nullif(lunch, false)) as lunch
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
<a href="/">new guest</a> | <a href='/list'>guest list</a><br>
<%= yield %>
</body>
</html>

@@ index
<h1>New Guest</h1>
<form action="/guest" method="post">
  <%= erb :guestform %>
  <input type="submit">
</form>

@@ editguest
<h1>Edit Guest</h1>
<form action="/guest/<%= @guest[:id] %>" method="post">
  <input type='hidden' name='_method' value='put'>
  <%= erb :guestform %>
  <input type="submit" value='update'>
</form>

<h2>Delete Guest</h2>
<form action="/guest/<%= @guest[:id] %>" method="post">
  <input type='hidden' name='_method' value='delete'>
  <input type='submit' value='delete guest'>
<form>

@@ guestform
  <fieldset>
    <label>Guest's Name*</label> <input <%= name_value(:guest_name) %> required> <br>
    <label>Visiting on*</label>  <input type='date' <%= name_value :visiting_on, :date %> placeholder="<%=Date.today.to_s%>" required><br>
    <label>Lunch?</label>        <input type='checkbox' <%= name_value :lunch, :checkbox %>> (please give at least 2 days notice)<br>
    <label>NDA?</label>          <input type='checkbox' <%= name_value :nda, :checkbox %>>
  </fieldset>
  <fieldset>
   <label>Your Name*</label>     <input <%= name_value :herokai_name %> required><br>
   <label>Notify Hipchat</label> <input type='checkbox' <%= name_value :notify_hipchat, :checkbox %>><br>
   <label>Notify GChat</label>   <input type='checkbox' <%= name_value :notify_gchat, :checkbox %>><br>
   <label>Notify SMS</label>     <input type='phonenumber' <%= name_value :notify_sms %> placeholder="your number"><br>
  </fieldset>
  <fieldset>
    <label>notes:</label><br>
    <textarea name="notes"><%= @guest[:notes] if @guest%></textarea><br>
  </fieldset>


@@ list
<h1>Overview</h1>
<% @overview.each do |day| %>
  <%= "<b><a href='?day=#{day[:visiting_on]}'>#{day[:visiting_on].strftime('%a %b %d')}</a>:</b> #{day[:total]} visiting (#{day[:lunch]} for lunch)" %>
  <br>
<% end %>

<h1><%=h @day %></h1>
<table>
<tr><th>guest</th><th>lunch/nda</th><th>for</th><th>notify</th><th>notes</th></tr>
<% @day_guests.each do |g| %>
  <tr>
    <td><%=h g[:guest_name] %></td>
    <td> <%= "lunch" if g[:lunch] %> <%= "nda" if g[:nda] %></td>
    <td><%=h g[:herokai_name] %></td>
    <td>
      <%= "hipchat" if g[:notify_hipchat] %>
      <%= "gchat" if g[:notify_gchat] %>
      <%= "sms #{g[:notify_sms]}" if g[:notify_sms] %>
    </td>
    <td class='last'><%=h g[:notes] %></td>
  </tr>
<% end %>
</table>


