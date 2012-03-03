class HomeController < ActionController::Base

  def index
  	render :layout => 'application'
  end

  def profile
  	#if session[:login] then
  	if not session[:uid] then
  		redirect_to root_url
  	else
      @jobs = Cron.all(conditions: {uid: session[:uid]})
      @jobs = @jobs.to_a
      if @jobs.size == 0 then
        @jobs = nil
      end
    	render :layout => 'application'
    end
  end

end
