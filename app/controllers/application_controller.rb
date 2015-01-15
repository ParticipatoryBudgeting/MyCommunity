# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def index
    session[:us] = nil unless session['collect_email']
    @login_failed = session['error'] == 'login'
    @register_failed = session['error'] == 'register'
    @collect_email = session['collect_email'] if session['collect_email']
    session['error'] = nil
    @categories = Category.all :order => "name asc"
    @locations = Cause.all(:group => 'city, district').group_by { |cause| cause.city }
    @budgets = Budget.all
  end
  
  def sobre_o_projeto
  end
  
  def apoiadores
  end
  
  def seja_um_voluntario
  end
        
  def fale_conosco
  end
  
  def send_contact_form
    ContactMailer.deliver_send_contact_form(params)
    render :nothing => true
  end

  def send_volunteer_form
    VolunteerMailer.deliver_send_volunteer_form(params)
    render :nothing => true
  end

  def termos_de_uso
  end
  
  def como_participar
  end

  private

  def budget_change_event
    params.has_key? :component and params[:component] == 'budget_filter' and params.has_key? :budget
  end

end
