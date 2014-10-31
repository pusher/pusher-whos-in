require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require "gravatar-ultimate"
require './lib/render_partial'
require 'pusher'
require 'mongo'


Pusher.url = ENV["PUSHER_URL"] || "http://#{ENV["WHOS_IN_KEY"]}:#{ENV["WHOS_IN_SECRET"]}@api.pusherapp.com/apps/#{ENV["WHOS_IN_ID"]}"


include Mongo

configure do
	if !ENV['MONGOLAB_URI']
	  conn = MongoClient.new("localhost", 27017)
	  set :mongo_connection, conn
	  set :mongo_db, conn.db('whos_in')
  else
		mongo_uri = ENV['MONGOLAB_URI']
		db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
		client = MongoClient.from_uri(mongo_uri)
		db = client.db(db_name)
		set :mongo_connection, client
		set :mongo_db, db
		db.collection_names.each { |name| puts name }
  end
end


# Set Sinatra variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public_folder, 'public'

# Application routes
get '/' do
  haml :index, :layout => :'layouts/application'
end

post '/people' do 
	people = people_from_json request.body.read
	Pusher['people_channel'].trigger('people_event', people)
end

post '/users/new' do 
	user_data, response_data = Hash.new, JSON.parse(request.body.read)
	user_data[:name], user_data[:mac], user_data[:email] = response_data["name"], response_data["mac address"], response_data["email address"]
	user_data[:gravatar] = Gravatar.new(user_data[:email]).image_url
	settings.mongo_db['users'].insert user_data
	{success: 200}.to_json
end

def people_from_json output
	addresses = JSON.parse output
	match_people_to_mac_addresses addresses
end

def match_people_to_mac_addresses addresses
	addresses.map! {|address| address["mac"]}
	people = settings.mongo_db['users']
	matches = people.find('mac' => {'$in' => addresses})
	matches.to_a.each { |match| people.update({"_id" => match["_id"]},{"$set" => {"last_seen" => Time.now}})}
	people.find('mac' => {'$in' => addresses}).to_a
end
