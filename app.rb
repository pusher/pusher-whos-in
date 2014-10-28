require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require "gravatar-ultimate"

# Helpers
require './lib/render_partial'

require 'pusher'

Pusher.url = "http://5b38b811cbe170b81ea1:658c86a2384410f3e45c@api.pusherapp.com/apps/94047"

# Set Sinatra variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public_folder, 'public'

# Application routes
get '/' do
	# `sh local_scanner.sh`
  haml :index, :layout => :'layouts/application'
end

post '/people' do 
	puts "getting it!"
	people = people_from_json request.body.read
	Pusher['people_channel'].trigger('people_event', people)
end

def people_from_json output
	addresses = get_addresses_from output
	names = get_names_from_file
	match_names_to_mac_addresses addresses, names
end

def get_addresses_from output
	JSON.parse(output).map do |person|
		{mac: person[0], last_seen: person[1]["last_seen"]}
	end
end

def get_names_from_file
	JSON.parse(IO.read('names.json'))
end

def match_names_to_mac_addresses addresses, names
	addresses.each do |address|
		match = names.find {|name| name["mac"] == address[:mac]}
		if match
			address[:name] = match["name"]
			address[:gravatar] = get_gravatar_from match["email"]
		end
		address[:name] = match ? match["name"] : nil
	end.partition {|data| data[:name] }.flatten
end

def get_gravatar_from email
	Gravatar.new(email).image_url
end