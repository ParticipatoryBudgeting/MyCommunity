class BudgetsController < ApplicationController
  def index
  end

  def create
    @budget = Budget.create params[:budget]

    @result = { :status => :ok, :success => true }
    respond_to do |format|
      format.json { render :json => @result.to_json }
    end
  end

  def new
    @user = session[:user]

    respond_to do |format|
      format.html
    end
  end

  def edit
  end

  def destroy
  end

  def update
  end

end