class HomeController < ActionController::Base

  def index
  	render :layout => 'application'
  end

  def profile
  	if not session[:login] then
  		redirect_to root_url
  	end
  end

end
