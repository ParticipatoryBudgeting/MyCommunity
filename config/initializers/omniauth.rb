ActionController::Dispatcher.middleware.use OmniAuth::Builder do
  provider :facebook, FACEBOOK_SETTINGS['app_id'], FACEBOOK_SETTINGS['app_secret'], :authorize_params => {:locale => 'pl'}
  provider :google_oauth2, GOOGLE_SETTINGS['cliend_id'], GOOGLE_SETTINGS['client_secret'], :name => 'google'
end