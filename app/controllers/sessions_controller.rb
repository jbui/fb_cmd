class SessionsController < ActionController::Base

	def create
		auth = request.env["omniauth.auth"]
		uid = auth.uid
		token = auth.credentials.token

		user = User.first(conditions: {uid: uid}) || User.create(uid, token)

		session[:login] = true
		redirect_to root_url
	end


	def destroy
		reset_session
		redirect_to root_url, :notice => "You're now signed out!"
	end

	def failure
		raise request.env["omniauth.auth"].to_yaml
		redirect_to root_url, :alert => "Auth Error: #{params[:message].humanize}"
	end

end
