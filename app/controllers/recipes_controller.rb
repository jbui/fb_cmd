
class RecipesController < ActionController::Base
	before_filter :setup

	# fbcommand line possible commands: http://fbcmd.dtompkins.com/commands
	def parse
		cmd = params[:q]
		cmd = cmd.split
		key_cmd = cmd[0]
		args = cmd[1..-1]

		case key_cmd
		when "birthday"
			happy_birthday
		end
		
	end

	private
	def setup
		@graph = Koala::Facebook::API.new('AAADqwRNaOCYBAN79GggRndUpr2DZCS1qPmgY6vorRLLoehoZCWbU7WiXteWRyqHPygiduoWuxcyjy2uLpRL1ZCdMwP8fveEmTFqgDw8kAZDZD')
	end

	def create_event
	end

	def create_post
		@graph.put_wall_post("hey, i'm learning kaola")
	end

end
