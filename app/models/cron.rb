class Cron
	include Mongoid::Document

	field :uid, :type=> Integer
	field :command, :type=> String

	# Creates a new user in the database
	def self.create(uid, command)
		create! do |cron|
			cron.uid = uid
			cron.command = command
		end
	end

end
