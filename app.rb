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

# Database of users

set :people, settings.mongo_db['users']

# Application routes
get '/' do
  haml :index, :layout => :'layouts/application'
end

post '/people' do
	protected!
	addresses = JSON.parse(request.body.read).map(&:values).flatten
	people = update_people_from addresses
	Pusher['people_channel'].trigger('people_event', people)
end

post '/users/new' do 
	user_data = JSON.parse(request.body.read)
	user_data["gravatar"], user_data["last_seen"] = Gravatar.new(user_data["email"]).image_url, Time.new(0)
	settings.mongo_db['users'].insert user_data
	{success: 200}.to_json
end

def status_by addresses
	Proc.new { |person| is_included_in_list?(person, addresses) ? set_presence_of(person, true) : inactive_for_ten_minutes?(person) ? set_presence_of(person, false) : nil }
end

def is_included_in_list? person, addresses
	addresses.include? person["mac"].upcase
end

def inactive_for_ten_minutes? person
	Time.now >= (person["last_seen"] + 10*60)
end

def set_presence_of person, status
	insertion = status ? {"last_seen" => Time.now, "present" => true} : {"present" => false }
	settings.people.update({"_id" => person["_id"]}, {"$set" => insertion})
end

def update_people_from addresses
	settings.people.find.map(&status_by(addresses)) and return settings.people.find.to_a
end