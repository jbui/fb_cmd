
class RecipesController < ActionController::Base
	before_filter :setup

	def parse
		create_post
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
