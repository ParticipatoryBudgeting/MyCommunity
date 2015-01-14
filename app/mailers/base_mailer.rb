class BaseMailer < ActionMailer::Base
  
  self.template_root = File.join(RAILS_ROOT, 'app', 'emails')
  
  helper :application
  layout 'base'
  
  def l(*args)
    I19n.l(*args)    
  end
  
  def defaults
    from ActionMailer::Base.smtp_settings[:user_name]
    sent_on Time.now
    content_type "text/html"
  end

  def default_recipient
    'filip.matuszewski@gmail.com'
  end
  
end