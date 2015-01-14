class CausesMailer < BaseMailer
  
  def send_comment_notification(cause)
    defaults
    subject "Projekt został skomentowany"
    if cause.email.nil?
      recipients [default_recipient]
    else
      recipients [cause.email, default_recipient]
    end
    body :cause => cause
  end
  
end