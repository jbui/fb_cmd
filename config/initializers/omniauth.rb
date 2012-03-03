Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, APP_CONFIG['FACEBOOK_KEY'], APP_CONFIG['FACEBOOK_SECRET'],
           :scope => APP_CONFIG['PERMISSIONS'], :display => 'popup'
end