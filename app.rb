require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require "gravatar-ultimate"
require './lib/render_partial'
require 'pusher'
require 'mongo'


Pusher.url = ENV["PUSHER_URL"]

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', ENV["PUSHER_URL"]]
  end
end

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
	protected!
	# people = people_from_json request.body.read
	people = process request.body.read
	Pusher['people_channel'].trigger('people_event', people)
end

post '/users/new' do 
	user_data, response_data = Hash.new, JSON.parse(request.body.read)
	user_data[:name], user_data[:mac], user_data[:email] = response_data["name"], response_data["mac address"].upcase, response_data["email address"]
	user_data[:gravatar] = Gravatar.new(user_data[:email]).image_url
	user_data[:last_seen] = Time.new(0)
	settings.mongo_db['users'].insert user_data
	{success: 200}.to_json
end

def process addresses
	addresses = JSON.parse(addresses).map {|address| address["mac"]}
	people = settings.mongo_db['users']
	people.find.each do |person|
		if addresses.include? person["mac"]
			people.update({"_id" => person["_id"]}, {"$set" => {"last_seen" => Time.now, "present" => true }})
		elsif !addresses.include?(person["mac"]) && (Time.now >= (person["last_seen"] + 10*60))
			people.update({"_id" => person["_id"]}, {"$set" => {"present" => false }})
		end
	end
	people.find.to_a
end




