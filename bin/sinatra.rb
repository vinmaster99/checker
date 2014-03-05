require 'sinatra'
require 'pstore'
require 'json'

# add to_i to compare boolean values
class TrueClass; def to_i; 1; end; end;
class FalseClass; def to_i; 0; end; end;

configure do
  @@css_array = ['/table.css', '/main.css']
  @@js_array = ['http://code.jquery.com/jquery.min.js', '/script.js']
  mime_type :json, 'application/json'
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, settings.root+'/views'
  set :public_folder, settings.root+'/public'
end

#module Helper
#end
#helpers Helper

helpers do
  def partial (template, locals = {})
    template = ('_'+template.to_s).to_sym     # rails partial convension
    erb(template, :layout => false, :locals => locals)
  end
end

get '/' do
  "<link rel='stylesheet' href='/main.css'/><div class='nav'><a href='/sites'>List all sites</a><a href='/sites/up'>List sites that are up</a><a href='/sites/down'>List sites that are down</a><a href='/sites/warning'>List sites that have warning</a><a href='/report'>Status codes count</a><a href='/report/:status'>Check sites with :status codes</a><a href='/cname'>Sites that is not hosted with us</a><a href='/history'>List the time checker script was ran</a></div>"
end

# get '/sites/?' do
['/sites', '/sites/'].each do |path|
  get path do
    timestamp_store = PStore.new("timestamp.pstore")
    array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

    data_store = PStore.new("data.pstore")
    @result = data_store.transaction { data_store.fetch(array.last, nil) }
    @timestamp = Time.at(array.last)

    erb :sites
  end
end

get '/sites/up' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  @timestamp = Time.at(array.last)
  @options = { :status => "Up" }

  erb :sites_sort
end

get '/sites/down' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  @timestamp = Time.at(array.last)
  @options = { :status => "Down" }
  
  erb :sites_sort
end

get '/sites/warning' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }
  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  @timestamp = Time.at(array.last)
  @options = { :status => "Warning" }
  erb :sites_sort
end

get '/cname' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  @timestamp = Time.at(array.last)
  @options = { :cname => "Down" }
  
  erb :sites_sort
end

get '/sites.json' do
  content_type :json
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }

  @result.to_json
end

get '/history' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }
  array.map {|epoch| Time.at(epoch)}.to_json
end

get '/report/?' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  statuses = { :sites => {}, :pages => {} }
  @result.each do |hash|
    if statuses[:sites][hash[:status]]
      statuses[:sites][hash[:status]] += 1
    else
      statuses[:sites][hash[:status]] = 1
    end
    hash[:labels].each do |label|
      if statuses[:pages][label[:status]]
        statuses[:pages][label[:status]] += 1
      else
        statuses[:pages][label[:status]] = 1
      end
    end
  end
  statuses.to_json
end

get '/report/:code' do |code|
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  sites = Array.new
  @result.each do |hash|
    if hash[:status] == code.to_i
      sites << hash[:domain]
    end
    hash[:labels].each do |label|
      sites << (hash[:domain]+label[:label]) if label[:status] == code.to_i
    end
  end
  if sites.empty?
    "No sites with #{code}"
  else
    sites.to_json
  end
end

=begin
not_found do
  #status 404
  #'not found'
  halt 404, 'You reached the end of the Internet'
end
=end
