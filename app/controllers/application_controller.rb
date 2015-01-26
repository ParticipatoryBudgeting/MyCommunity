# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :get_filter_budget

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
    p @locations
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

  def filter_field_change_event(field)
    params.has_key? :component and params[:component] == "#{field.to_s}_filter" and params.has_key? field
  end

  def budget_change_event
    filter_field_change_event(:budget)
  end

  def city_change_event
    filter_field_change_event(:city)
  end

  def district_change_event
    filter_field_change_event(:district)
  end

  def set_filter_budget(budget)
    session[:budget_filter] = budget.to_i
  end

  def get_filter_budget
    session[:budget_filter] or ""
  end

  def set_filter_city(city)
    session[:city_filter] = city
  end

  def get_filter_city
    session[:city_filter] or ""
  end

  def set_filter_district(district)
    session[:district_filter] = district
  end

  def get_filter_district
    session[:district_filter] or ""
  end

  def reset_filter
    set_filter_budget 0
    set_filter_city ''
    set_filter_district ''
  end

  def reset_filter_event
    params.has_key? :component and params[:component] == "reset_filter"
  end

end
