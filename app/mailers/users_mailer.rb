class UsersMailer < BaseMailer
  
  def registro(user)
    defaults
    subject "Witamy na community.societybuilder.pl"
    content_type "text/html"
    recipients user.email
    body :user => user
  end
  
end