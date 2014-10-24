require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'

# Helpers
require './lib/render_partial'

require 'pusher'

Pusher.url = "http://5b38b811cbe170b81ea1:658c86a2384410f3e45c@api.pusherapp.com/apps/94047"

Pusher['test_channel'].trigger('my_event', {
  message: 'hello world'
})

# Set Sinatra variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public_folder, 'public'

# Application routes
get '/' do
  haml :index, :layout => :'layouts/application'
end

get '/about' do
  haml :about, :layout => :'layouts/application'
end

get '/people' do 
	people = people_from_json `sh local_scanner.sh`
	return people.to_json
end

def people_from_json output
	JSON.parse(output).map do |person|
		{mac: person[0], last_seen: person[1]["last_seen"]}
	end
end

def get_people
	loop do
		puts "Getting people..."
		people = people_from_json `sh local_scanner.sh`
		puts "Triggering event..."
		Pusher['people_channel'].trigger('people_event', people)
		sleep 5
	end
end

# get_people