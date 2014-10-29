require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require "gravatar-ultimate"


# Helpers
require './lib/render_partial'

require 'pusher'

Pusher.url = "http://5b38b811cbe170b81ea1:658c86a2384410f3e45c@api.pusherapp.com/apps/94047"

require 'mongo'

include Mongo

configure do
	if !ENV['MONGOLAB_URI']
	  conn = MongoClient.new("localhost", 27017)
	  set :mongo_connection, conn
	  set :mongo_db, conn.db('whos_in')
  else
  	# PROBLEM HERE !!!!
		mongo_uri = ENV['MONGOLAB_URI']
		db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
		client = MongoClient.from_uri(mongo_uri)
		db = client.db(db_name)
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

# def in_groups array, odd_number, even_number
# 	number = odd_number
# 	array = array.each_slice(even_number).to_a
# 	array.each_with_index do |sub_array, index|
# 		puts number
# 		until sub_array.length <= number
# 			array[index + 1] = [] if !array[index + 1]
# 			array[index + 1] << sub_array.pop
# 		end
# 		number = (number == odd_number) ? even_number : odd_number
# 	end
# 	return array
# end