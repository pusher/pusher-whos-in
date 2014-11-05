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
	people = update_people_from request.body.read
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

def status_by addresses, people = settings.mongo_db['users']
	Proc.new do |person|
		is_included_in_list?(person, addresses) ? set_presence_of(person, true) : inactive_for_ten_minutes?(person) ? set_presence_of(person, false) : nil
	end
end

def is_included_in_list? person, addresses
	addresses.include? person["mac"]
end

def inactive_for_ten_minutes? person
	Time.now >= (person["last_seen"] + 10*60)
end

def set_presence_of person, status, people = settings.mongo_db['users']
	insertion = status ? {"last_seen" => Time.now, "present" => true} : {"present" => false }
	people.update({"_id" => person["_id"]}, {"$set" => insertion})
end

def update_people_from addresses, people = settings.mongo_db['users']
	addresses = JSON.parse(addresses).map {|address| address["mac"]}
	people.find.map(&status_by(addresses))
	people.find.to_a
end