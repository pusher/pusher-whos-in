require './app'
require "gravatar-ultimate"

people = JSON.parse IO.read('names.json')

people.each do |person|
	person["gravatar"] = Gravatar.new(person["email"]).image_url
	settings.mongo_db['users'].insert person
end