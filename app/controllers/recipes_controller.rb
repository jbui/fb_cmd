
class RecipesController < ActionController::Base
	before_filter :setup

	# fbcommand line possible commands: http://fbcmd.dtompkins.com/commands
	def parse
		cmd = params[:q]
		cmd = CGI.unescapeHTML(cmd)

		cmd = cmd.split
		key_cmd = cmd[0]
		args = cmd[1..-1]

		case key_cmd
		when "birthday"
			happy_birthday

		when "help"
			query = URI.escape(args.join(" "))
			link = "http://lmgtfy.com/?q=#{query}&l=1"
			create_link("Help I'm a noob!", link)
		end
		
	end

	private
	def setup
		@graph = Koala::Facebook::API.new('AAADqwRNaOCYBAIv9uZC1zLpJ5ueHpQ3Lv4ZCMZB91kw7AZC4zi7jIegrrUKqZAaCTocrX6VFxG7m5HFZBWN6Exo8kqzlbOpPaSLYSd3HcZAegZDZD')
	end

	def create_event
	end

	# One attachment type: https://developers.facebook.com/docs/guides/attachments/
	def create_link(message, link, target_id="me")
		create_post(message, {"link" => link}, target_id)
	end	

	def create_post(message, attachment={}, target_id="me")
    @graph.put_wall_post(message, attachment, target_id)
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
