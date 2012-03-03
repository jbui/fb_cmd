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
      text = CGI.unescapeHTML(query)
      link = "http://lmgtfy.com/?q=#{query}&l=1"
      if tagged_users.length == 0
        create_link("Google this: #{text}", link)
      else
        create_link("Google this: #{text}", link, tagged_users)
      end

    when "yelp"
      url = query_yelp(URI.escape(args.join(" ")))

      if tagged_users.length == 0
        create_link("Anyone want to get food?", url)
      else
        create_link("Anyone want to get food?", url, tagged_users)
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
    	if args.length > 1
    	  comic = args[0]
    	else
    		comic = %w[challengeaccepted derp etwbte fap fu fuckyeah happy herpderp hm lol mad megusta okay poker sad smile thefuck troll why yuno].sample
    	end
    	
			open("http://kevinformatics.com/rage/#{comic}.png") {|f|
			   File.open("#{Rails.root}/tmp/rage_#{Process.pid}.png","wb") do |file|
			     file.puts f.read
			   end
			}
    	@graph.put_picture "#{Rails.root}/tmp/rage_#{Process.pid}.png", 

    # more whens
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
