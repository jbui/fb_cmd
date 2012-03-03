
class RecipesController < ActionController::Base
	before_filter :setup

	def parse
		happy_birthday
	end

	private
	def setup
		@graph = Koala::Facebook::API.new('AAADqwRNaOCYBAIv9uZC1zLpJ5ueHpQ3Lv4ZCMZB91kw7AZC4zi7jIegrrUKqZAaCTocrX6VFxG7m5HFZBWN6Exo8kqzlbOpPaSLYSd3HcZAegZDZD')
	end

	def create_event
	end

	def create_post
		#@graph.put_wall_post("hey, i'm learning kaola")

		shit = @graph.fql_query('select uid,name,birthday_date from user where uid in (select uid2 from friend where uid1=me())')
		raise shit.to_yaml
	end

	def happy_birthday
		date = Time.now.strftime("%m/%d").to_s
		fql_query = 'select uid,name,birthday_date from user where uid in (select uid2 from friend where uid1=me()) and strpos(birthday_date, "' + date + '") >= 0'
		message = 'HAPPY BIRTHDAY!'

		users = @graph.fql_query(fql_query)
		users.each do |user|
			@graph.put_wall_post(message, {}, user['uid'].to_s)
		end

		render :nothing => true
	end

	#@graph.put_wall_post("explodingdog!", {:name => "i love loving you", :link => "http://www.explodingdog.com/title/ilovelovingyou.html"}, "tmiley")


end
