class HomeController < ActionController::Base
  def index
  	raise APP_CONFIG['app_id'].to_s
  end
end
