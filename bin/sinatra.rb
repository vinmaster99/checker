require 'sinatra'
require 'pstore'
require 'json'

class TrueClass; def to_i; 1; end; end;
class FalseClass; def to_i; 0; end; end;

configure do
  @@css_array = ['table.css']
  set :views, root+'/views'
end

helpers do
  def partial (template, locals = {})
    template = ('_'+template.to_s).to_sym     # rails partial convension
    erb(template, :layout => false, :locals => locals)
  end
end

get '/' do
  "Hello, World"
end

# get '/sites/?' do
['/sites', '/sites/'].each do |path|
  get path do
    timestamp_store = PStore.new("timestamp.pstore")
    array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

    data_store = PStore.new("data.pstore")
    @result = data_store.transaction { data_store.fetch(array.last, nil) }
    @timestamp = Time.at(array.last)

    #erb :sites, :layout => :table_layout
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

  #erb :sites_sort, :layout => :table_layout
  erb :sites_sort
end

get '/sites/down' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.last, nil) }
  @timestamp = Time.at(array.last)
  @options = { :status => "Down" }
  
  #erb :sites_sort, :layout => :table_layout
  erb :sites_sort
end

get '/sites.json' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }

  data_store = PStore.new("data.pstore")
  @result = data_store.transaction { data_store.fetch(array.first, nil) }

  erb :sitesjson
end

get '/history' do
  timestamp_store = PStore.new("timestamp.pstore")
  array = timestamp_store.transaction { timestamp_store.fetch(:times, Array.new) }
  array.map {|epoch| Time.at(epoch)}.to_json
end

get %r{(table.css|sites\/table.css)$} do
  erb :tablecss
end
=begin
not_found do
  #status 404
  #'not found'
  halt 404, 'page not found'
end
=end
