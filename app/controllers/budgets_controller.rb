class BudgetsController < ApplicationController
  def index
  end

  def create
    require 'pry'
    binding.pry
    @budget = Budget.new params[:budget]
    @budget.user_id = session[:user].id
    @budget.save
    @result = { :status => :ok, :success => true }
    respond_to do |format|
      format.json { render :json => @result.to_json }
    end
  end

  def new
    @budget = Budget.new
    @action = "Utwórz"
    respond_to do |format|
      format.html
    end
  end

  def edit
  end

  def destroy
  end

  def update
    @budget = Budget.find params[:budget][:id]
    @budget.update_attributes params[:budget].except(:id)
    @result = { :status => :ok, :success => true, :budget => @budget }
    respond_to do |format|
      format.json { render :json => @result.to_json }
    end  
  end

  def show
    @budget = Budget.find params[:id]
    @action = "Utwórz"
    @user = session[:user]
  end

end