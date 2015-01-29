module BudgetsHelper

  def display_pre_days(budget)
    if not budget.preparation_date.nil? and not budget.creation_date.nil?
      (budget.preparation_date - budget.creation_date).days
    else
      ''
    end
  end
end
