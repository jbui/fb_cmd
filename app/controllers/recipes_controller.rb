require 'net/http'
require 'xmlsimple'

class RecipesController < ActionController::Base

  # fbcommand line possible commands: http://fbcmd.dtompkins.com/commands
  def parse
    @uid = params[:uid]
    @user = User.first(conditions: {uid: @uid})
    @token = @user.token
    @graph = Koala::Facebook::API.new(@token)
    @rest = Koala::Facebook::API.new(@token)

    cmd = params[:q]
    cmd = CGI.unescapeHTML(cmd)

    #CRON JOB?????
    if cmd.include? "/week" or cmd.include? "/day" or cmd.include? "/month" then
      Cron.create(@uid, cmd)
    end


    # @[502558370:James Bui] 
    tagged_users = cmd.scan(/@\[(\d+):[\w ]+\]/).flatten
    tagged_names = cmd.scan(/@\[\d+:([\w ]+)\]/).flatten

    args = cmd.gsub(/@\[(\d+):[\w ]+\]/, "")
    args = args.split

    key_cmd = args[0]
    args = args[1..-1]

    # For any command there exist possible parsed params:
    # * key_cmd, first word in command
    # * args, array of arguments that follow (stable)
    # * tagged_users, array of uids of tagged users that follow (stable)
    case key_cmd

    when "birthday"
      happy_birthday
      @redirect_url = "https://www.facebook.com/me"

    when "help"
      query = URI.escape(args.join(" "))
      link = "http://lmgtfy.com/?q=#{query}&l=1"
      if tagged_users.length == 0
        create_link("oh man guys, let me google this for you.", link)
      else
        create_link("oh man guys, let me google this for you.", link, tagged_users)
      end

    when "yelp"
      url = query_yelp(URI.escape(args.join(" ")))

      if tagged_users.length == 0
        create_link("Anyone want to get food?", url)
      else
        create_link("Wanna go get food?", url, tagged_users)
      end

    when "location"
      get_location

    when "hangout"
      string = (0...4).map{65.+(rand(25)).chr}.join
      link = "http://fbcmd.herokuapp.com/get_video/" + string
      if tagged_users.length == 0
        create_link("Hangout with me!", link)
      else
        create_link("Hangout with me!", link, tagged_users)
      end

    when "rage"
    	require "open-uri"
    	if args.length > 0
    	  comic = args[0]
    	else
    		comic = %w[challengeaccepted derp etwbte fap fu fuckyeah happy herpderp hm lol mad megusta okay poker sad smile thefuck troll why yuno].sample
    	end
    
      rage_path = "http://kevinformatics.com/rage/#{comic}.png"
    	# rage_path = "#{Rails.root}/tmp/rage_#{Process.pid}.png"	
			# open("http://kevinformatics.com/rage/#{comic}.png") {|f|
			#    File.open(rage_path,"wb") do |file|
			#      file.puts f.read
			#    end
			# }

		if tagged_users.length == 0 then
			@graph.put_wall_post("", {:picture => rage_path})
	    else
	    	tagged_users.each do |uid|
	    		@graph.put_wall_post("", {:picture => rage_path}, uid.to_s)
	    	end
	    end
	when "youtube"
		  url = query_youtube(URI.escape(args.join(" ")))

		  if tagged_users.length == 0
	        create_link("everyone watch this", url)
	      else
	        create_link("watch this", url, tagged_users)
	      end
	when "image"
		  url = query_image(URI.escape(args.join(" ")))

		  if tagged_users.length == 0
	        create_link("everyone look at this", url)
	      else
	        create_link("look at this!", url, tagged_users)
	      end
	when "song"
		  url = query_grooves(URI.escape(args.join(" ")))

		  if tagged_users.length == 0
	        create_link("everyone listen to this", url)
	      else
	        create_link("listen to this!", url, tagged_users)
	      end
	when "gosling"
		#GHETTTOO
		gosling = [
			'http://25.media.tumblr.com/tumblr_lzoiqwPfmo1r8s5fgo1_500.jpg',
			'http://26.media.tumblr.com/tumblr_lysgcahQTa1r8s5fgo1_500.jpg',
			'http://24.media.tumblr.com/tumblr_lyqzfn8g4X1r8s5fgo1_500.jpg',
			'http://28.media.tumblr.com/tumblr_lyqywhNViy1r8s5fgo1_500.jpg',
			'http://www.tumblr.com/photo/1280/ryangoslinglitmeme/16364001600/1/tumblr_ly8ch6t5qN1r8s5fg',
			'http://29.media.tumblr.com/tumblr_ly7q1ii9yG1r8s5fgo1_500.png',
			'http://30.media.tumblr.com/tumblr_ly6w6qEeH11r8s5fgo1_500.jpg',
			'http://24.media.tumblr.com/tumblr_ly5vtb6in51r8s5fgo1_400.jpg',
			'http://www.tumblr.com/photo/1280/ryangoslinglitmeme/16235389039/1/tumblr_ly5u1ekFJE1r8s5fg'
		]
		if tagged_users.length == 0
			#create_link("everyone listen to this", url)
		else
			create_link("Hey girl... ;)", gosling[rand(gosling.size)], tagged_users)
		end

	end

    render :text => @redirect_url
  end

  private

  # Wraps the Koala wall post. 
  # Requires a message and defaults to posting on own wall
  # Pass in an array of uids (or one) to post to walls
  # target_id MUST BE AN ARRAY IF PASSED IN
  def create_post(message, attachment={}, target_id="me")
    if target_id == "me"
      @graph.put_wall_post(message, attachment, target_id)
    else
      target_id.each do |uid|
        @graph.put_wall_post(message, attachment, uid)
      end
    end
  end

  # Wrapper around create_post for links
  # Requires a message and link, defaults to posting on own wall
  # else pass in a single or array of uids to post on
  def create_link(message, link, target_id="me")
    create_post(message, {"link" => link}, target_id)
  end 

  # Date needs to be in unix timestamp
  # invitelist is just an array of uids, json, string format
  def create_event(name, date, invite_list)
  	event_info = '{"name":"'+name+'", "start_time": '+date+'}'
  	eid = @rest.rest_call('events.create', event_info: event_info)
  	@rest.rest_call('events.invite',  eid: eid, uids: invite_list)
  end

  # Say happy birthday to everyone who has a birthday today
  def happy_birthday
    date = Time.now.strftime("%m/%d").to_s
    fql_query = 'select uid,name,birthday_date from user where uid in (select uid2 from friend where uid1=me()) and strpos(birthday_date, "' + date + '") >= 0'
    message = 'HAPPY BIRTHDAY!'

    users = @graph.fql_query(fql_query)
    uids = users.map {|user| user['uid'].to_s}
    @graph.put_wall_post(message, {}, uids)

    # users.each do |user|
    # logger.info(user['uid'])
    # @graph.put_wall_post(message, {}, user['uid'].to_s)
    # end
  end

  # Uses freegeoip to get geolocation
  def get_location

    ip = request.remote_ip
    if ip == "127.0.0.1"
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

  # Queries yelp with the terman geolocated lat/lon
  def query_yelp(term)
    location = get_location
    yelp_api = "api.yelp.com"
    yelp_request = "/business_review_search?term=#{term}&lat=#{location['latitude']}&long=#{location['longitude']}&radius=25&limit=5&ywsid=#{APP_CONFIG['YELP_KEY']}"


    json_resp = Net::HTTP.get_response(yelp_api, yelp_request).body
    json_resp = ActiveSupport::JSON.decode(json_resp)

    return json_resp["businesses"][0]["url"]
  end

  # def post_wall(message, target_uid = nil)

  # 	if not target_uid then
  # 		@graph.put_wall_post(message)
  # 	else

  # 	end

  # 	render :nothing => true
  # end

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
  def query_image(query_string, target_uid = nil)
    query_url = "http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=" + query_string
    uri = URI(query_url)
    images = JSON.parse(Net::HTTP.get(uri))
    img_url = images['responseData']['results'][0]['url']

    return img_url
  end

  # Gets a random youtube video from a query
  def query_youtube(query_string, target_uid = nil)
    query_url = "http://gdata.youtube.com/feeds/api/videos?q=" + query_string + "&orderby=viewCount"
    uri = URI(query_url)
    videos = XmlSimple.xml_in(Net::HTTP.get(uri))
    video_url = videos['entry'][0]['link'][0]['href']
	return video_url
  end

  def query_grooves(query_string)
  	query_url = "http://tinysong.com/a/" + query_string + "?format=json&key=0f63531cd126cfc6ff86cc1e3b3f7a33"
  	uri = URI(query_url)
  	song = Net::HTTP.get(uri)
  	song = song.gsub("\\", "").gsub("\"", "")
  	return song
  end

end

