class ContactMailer < BaseMailer

  def send_contact_form(form_data)
    defaults
    subject "Wiadomość z formularza kontaktowego"
    recipients [default_recipient]
    body :data => form_data
  end  

end