FACEBOOK_SETTINGS = YAML::load_file("#{Rails.root}/config/facebook.yaml")[Rails.env]
GOOGLE_SETTINGS = YAML::load_file("#{Rails.root}/config/google.yaml")[Rails.env]
TWITTER_SETTINGS = YAML::load_file("#{Rails.root}/config/twitter.yaml")[Rails.env]