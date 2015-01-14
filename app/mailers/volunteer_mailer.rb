class VolunteerMailer < BaseMailer
    def send_volunteer_form(form_data)
    defaults
    subject "Wiadomość z formularza dla wolontariuszy"
    recipients [default_recipient]
    body :data => form_data
  end
  
end