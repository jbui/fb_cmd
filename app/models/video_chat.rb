class VideoChat

  api_key = "12538711"
  api_secret = "b246dd810d2834d3a87d253de2247b57ce0a6251"

  # remote_address is found in controller as request.remote_addr
  #def initialize( remote_address, api_key=api_key, api_secret=api_secret )
  #  opentok = OpenTok::OpenTokSDK.new api_key, api_secret
  #  session_properties = {OpenTok::SessionPropertyConstants::P2P_PREFERENCE => "disabled"}
  #  session = opentok.create_session remote_addr session_properties
  #  token = opentok.generate_token :session_id => session, :role => OpenTok::RoleConstants::PUBLISHER

  #  #API_URL = "https://api.opentok.com/hl"
  #end

end
