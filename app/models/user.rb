class User
	include Mongoid::Document

	field :uid, :type=> Integer
	field :token, :type=> String

	# Creates a new user in the database
	def self.create(uid, token)
		create! do |user|
			user.uid = uid
			user.token = token
		endx	
	end

end
