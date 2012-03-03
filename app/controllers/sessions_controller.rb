class SessionsController < ActionController::Base

	def create
		auth = request.env["omniauth.auth"]
		uid = auth.uid
		token = auth.credentials.token

		user = User.first(conditions: {uid: uid}).update_attributes!(uid: uid) || User.create(uid, token)

		session[:login] = true
        session[:token] = user.token
		redirect_to '/profile'
	end


	def destroy
		reset_session
		redirect_to root_url, :notice => "You're now signed out!"
	end

	def failure
		raise request.env["omniauth.auth"].to_yaml
		redirect_to root_url, :alert => "Auth Error: #{params[:message].humanize}"
	end
    
    # def create
    #   @facebook_key = APP_CONFIG['FACEBOOK_KEY'].to_s
    #   @redirect = APP_CONFIG['REDIRECT_URI']
    #   @permission = APP_CONFIG['PERMISSION']
    #   redirect_url = "http://www.facebook.com/dialog/oauth" +
    #                   "?client_id=" + @facebook_key + "&redirect_uri=" + @redirect_uri +
    #                   "?scope=" + @permission

    #   redirect :to => redirect_url
    # end

    # def redirect
    #   
    #   
    # end



end
