class AdminController < ApplicationController

  before_filter :authorize, :except => [:index, :login]
  helper_method :current_user, :cause_sort_column, :budget_sort_column, :sort_direction, :user_sort_column
  
  def index
    if session[:user_id]
      redirect_to :action => :show_causes
    end
  end
  
  def login
    user = User.authenticate(params[:username], params[:password])
    if user
      session[:user_id] = user.id
      flash[:message] = "Zostałeś zalogowany."
      redirect_to :action => :show_causes
    else
      flash[:message] = "Nie znaleziono użytkownika."
      redirect_to :action => :index
    end
  end
  
  def logout
    session[:user_id] = nil
    flash[:message] = "Zostałeś wylogowany."
    redirect_to :action => :index
  end
  
  def show_budgets
    where = '(budgets.id > 0)'
    where << " and (budgets.user_id like '%#{params[:user_id]}%')" unless params[:user_id].blank?
    where << " and (budgets.name like '%#{params[:name]}%')" unless params[:name].blank?
    where << " and (budgets.type like '%#{params[:type]}%')" unless params[:type].blank?
    @budgets2 = Admin.get_budgets(where)
    @budgets = Budget.paginate :all, :conditions => where, :page => params[:page], :per_page => 10, :order => "`#{budget_sort_column}` #{sort_direction}"
  end

  def show_causes
    params[:category] = "0" if params[:category].blank?
    where = '(causes.id > 0) and (causes.submited = 1)'
    where << " and (causes.author like '%#{params[:author]}%')" unless params[:author].blank? 
    where << " and (causes.title like '%#{params[:title]}%')" unless params[:title].blank?
    where << " and (causes.abstract like '%#{params[:abstract]}%')" unless params[:abstract].blank?
    where << " and (causes.category_id = '#{params[:category]}')" unless params[:category] == "0"
    @causes2 = Admin.get_causes(where)
    @causes = Cause.paginate :all, :conditions => where, :joins => :category, :page => params[:page], :per_page => 10, :order => "#{cause_sort_column} #{sort_direction}"
    @categories = [Category.new(:id => 0, :name => 'Todos')] + Category.find(:all)
  end
  
  def show_users_list
    @twitter_users = Admin.get_total_twitter_users
    @facebook_users = Admin.get_total_facebook_users
    @gmail_users = Admin.get_total_gmail_users
    @users2 = Admin.get_users
    @users = User.paginate(:all,:page => params[:page], :per_page => 10, :order => "#{user_sort_column} #{sort_direction}")
  end
  
  def show_rejected_causes
    params[:category] = "0" if params[:category].blank?
    where = '(causes.is_rejected = 1) and (causes.submited = 1)'
    where << " and (causes.author like '%#{params[:author]}%')" unless params[:author].blank? 
    where << " and (causes.title like '%#{params[:title]}%')" unless params[:title].blank?
    where << " and (causes.abstract like '%#{params[:abstract]}%')" unless params[:abstract].blank?
    where << " and (causes.category_id = '#{params[:category]}')" unless params[:category] == "0"
    @causes2 = Admin.get_rejected_causes(where)
    @causes = Cause.paginate :all, :joins => :category, :conditions => where, :page => params[:page], :per_page => 10, :order => "#{cause_sort_column} #{sort_direction}"
    @categories = [Category.new(:id => 0, :name => 'Todos')] + Category.find(:all)
  end
  
  def delete_cause
    @cause = Cause.find(params[:id])
    @cause.destroy
    redirect_to request.referer
  end
  
  def accept_cause
    @cause = Cause.find(params[:id])
    @cause.update_attributes :is_rejected => 0
    redirect_to request.referer
  end
  
  def reject_cause
    @cause = Cause.find(params[:id])
    @cause.update_attributes :is_rejected => 1
    redirect_to request.referer
  end

  def update_cause_likes
    @cause = Cause.find(params[:id])
    url = "http://www.portoalegre.cc/causas/#{@cause.category.name.urlize}/#{@cause.title.urlize}/#{@cause.id}"
    response = ActiveSupport::JSON.decode(RestClient.get("https://graph.facebook.com/#{url}"))
    @cause.update_attributes :likes => response["shares"].nil? ? 0 : response["shares"], :last_likes_update => Time.now
    redirect_to request.referer
  end

  def show_categories_list
    @categories = Category.paginate(:all,:page => params[:page], :per_page => 10, :order => "#{category_sort_column} #{sort_direction}")
  end

  def edit_category
    @category = Category.find(params[:id])
  end

  def update_category
   @category = Category.find(params[:id])

    if @category.update_attributes(params[:category])
      flash[:notice] = 'Kategoria została zaktualizowana.'
      redirect_to show_categories_url
    else
      render :action => "edit_category"
    end
  end

  def new_category
    @category = Category.new
  end

  def create_category
    @category = Category.new(params[:category])

    if @category.save
      flash[:notice] = 'Kategoria została utworzona.'
      redirect_to show_categories_url
    else
      render :action => "new"
    end
  end

  def edit_cause
    @cause = Cause.find params[:id]
  end

  def update_cause
   @cause = Cause.find(params[:id])

    if @cause.update_attributes(params[:cause])
      flash[:notice] = 'Projekt został zaktualizowany.'
      redirect_to show_causes_url
    else
      render :action => "edit_cause"
    end
  end

  def import_cause
    uploaded_file = params[:cause][:file]

    local_file = File.new('/tmp/' + uploaded_file.original_filename, "w")
    local_file.write(uploaded_file.read)
    local_file.close

    result = Import.start(local_file.path)

    flash[:notice] = 'Plik z projektami został zaimportowany'
    redirect_to show_causes_url
  end

  def destroy_budget
    budget = Budget.find(params[:id])
    causes_num = Cause.where(:budget_id => budget.id).size
    if causes_num > 0
      flash[:error] = 'Istnieją projekty przypisane do budżetu.'
    else
      budget.destroy
      flash[:notice] = 'Budżet został pomyślnie usunięty'
    end
    redirect_to show_budgets_path
  end
  
  private  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def authorize
    if session[:user_id]
        true
    else
      flash[:error] = "Brak uprawnień do zasobu."  
      redirect_to :action => :index
      false  
    end 
  end
  
  def cause_sort_column
    %w[categories.name  title abstract local district author created_at views likes updated_at created_at].include?(params[:sort]) ? params[:sort] : "created_at"
  end

  def budget_sort_column
    %w[created_at name type from to participants_count value user_id].include?(params[:sort]) ? params[:sort] : "created_at"
  end

  def user_sort_column
    %w[username  name last_sign_in location twitter_user_id google_email facebook_id].include?(params[:sort]) ? params[:sort] : "last_sign_in"
  end

  def category_sort_column
    %w[name].include?(params[:sort]) ? params[:sort] : "updated_at"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
  
end
