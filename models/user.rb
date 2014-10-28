require 'mongoid'

class User

	include Mongoid::Document

	field :name, type: String
	field :email, type: String
	field :gravatar, type: String

end