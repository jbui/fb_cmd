require 'net/http'
require 'xmlsimple'

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

		when "location"
			get_location(fake_address=true)
		end


	end
	
	private
	def setup
		@uid = '502558370'
		@token = 'AAADqwRNaOCYBAMy1wW9USHJ7X1FccFw38azlP4gbADTZANx1DZCGSsl5Y9VmZCb0QDsg4qTZAFNZBXCZC7wzcrx9e3RBWSf5xx50EuZB4cFwgZDZD'
		@graph = Koala::Facebook::API.new(@token)
		@rest = Koala::Facebook::API.new(@token)
	end

	# Say happy birthday to everyone
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

	def get_location(fake_address=false)

		ip = request.remote_ip
		if fake_address
			ip = "169.228.145.85"
		end

		geolocation_domain = "freegeoip.net"
		geolocation_request = "/json/#{ip}"
		json_resp = Net::HTTP.get_response(geolocation_domain, geolocation_request).body
		json_resp = ActiveSupport::JSON.decode(json_resp)

		# Example Response
		# {"city"=>"La Jolla", "region_code"=>"CA", "longitude"=>"-117.236", 
		#  "region_name"=>"California", "country_code"=>"US", "latitude"=>"32.8807", 
		#  "country_name"=>"United States", "ip"=>"169.228.145.85", 
		#  "zipcode"=>"92093", "metrocode"=>"825"}
		return json_resp

	end

	# Clear all notifications
	def clear_notifications
		fql_query = 'SELECT notification_id FROM notification WHERE recipient_id = ' + @uid + ' AND is_unread = 1'
		id_list = ''
		notifications = @graph.fql_query(fql_query)
		notifications.each do |notification|
			id_list = notification['notification_id'] + "," + id_list
		end

		@rest.rest_call('notifications.markRead', notification_ids: id_list)
		render :nothing => true
	end

	# Gets a random image from google search
	def post_image(query_string, target_uid = nil)
		query_url = "http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=" + query_string
		uri = URI(query_url)
		images = JSON.parse(Net::HTTP.get(uri))
		img_url = images['responseData']['results'][0]['url']

		if target_uid then
			@graph.put_wall_post("", {:picture => img_url}, target_uid.to_s)
		else
			@graph.put_wall_post("", {:picture => img_url})
		end

		render :nothing => true
	end

	# Gets a random youtube video from a query
	def post_video(query_string, target_uid = nil)
		query_url = "http://gdata.youtube.com/feeds/api/videos?q=" + query_string + "&orderby=viewCount"
		uri = URI(query_url)
		videos = XmlSimple.xml_in(Net::HTTP.get(uri))
		video_url = videos['entry'][0]['link'][0]['href']

		if target_uid then
			@graph.put_wall_post("", {:link => video_url}, target_uid.to_s)
		else
			@graph.put_wall_post("", {:link => video_url})
		end

		render :nothing => true
	end
end



















