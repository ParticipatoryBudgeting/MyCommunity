# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # for jquery
  def csrf_meta_tag
    if protect_against_forgery?
      out = %(<meta name="csrf-param" content="%s"/>\n)
      out << %(<meta name="csrf-token" content="%s"/>)
      out % [ Rack::Utils.escape_html(request_forgery_protection_token),
      Rack::Utils.escape_html(form_authenticity_token) ]
    end
  end
  
  # get user image
  def user_image(user, width = 56, height = 56)
    image_url = user.profile_image_url.blank? ? "/img/avatar.jpg" : user.profile_image_url
    image_src =  %{ <img id="image" src="#{image_url}" width="#{width}" height="#{height}" class="fl" alt="#{user.name}" /> }
    if user.facebook_id
      profile_url = %{ http://www.facebook.com/profile.php?id=#{user.facebook_id}}
    elsif user.twitter_username
      profile_url = %{ http://twitter.com/#!/#{user.twitter_username} }
    end
    if profile_url 
      link_to image_src, profile_url, :target => "_blank"
    else
      image_src
    end
  end
  
  def logged_user?
    # usuario esta na sessão, pertence a classe usuário e não é do twitter faltando digitar email
    !session[:user].blank? && session[:user].class == User && !session['collect_email']
  end
  
  def current_user
    if logged_user?
      session[:user]
    else
      nil
    end
  end
  
  def snippet(thought) 
    wordcount = 10 
    thought.split[0..(wordcount-1)].join(" ") + (thought.split.size > wordcount ? "..." : "") 
  end

  def budget_filter
    session[:budget_filter] || ""
  end

  def budgets_select(budgets, selected_budget_id)
    disabled_ids = budgets.reduce([]) { |m, b| b.locked ? m << b.id : m }
    selected_budget_id = '' if disabled_ids.include?(selected_budget_id)
    highlight_blocked = lambda { |b| [(b.locked ? b.name + ' [Zablokowany]' : b.name), b.id] }
    select :cause, :budget_id, budgets.map(&highlight_blocked), :disabled => disabled_ids, :selected => selected_budget_id.to_i
  end

  def budgets_filter_select(budgets, selected)
    empty_budget = Struct.new(:id, :name, :locked, :city)
    budget = empty_budget.new('0', 'Wszystkie', false, '')
    budgets.unshift(budget)
    row_structure = lambda { |b| [b.name, b.id, {'data-locked' => b.locked ? 1 : 0, 'data-city' => b.city}] }
    select('budget', 'budget_id', options_for_select(budgets.map(&row_structure), selected), {}, {:style => 'width:100%'})
  end

  def options_for_select(container, selected = nil)
    return container if String === container
    container = container.to_a if Hash === container
    selected, disabled = extract_selected_and_disabled(selected)

    options_for_select = container.inject([]) do |options, element|
      html_attributes = option_html_attributes(element)
      text, value = option_text_and_value(element)
      selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
      disabled_attribute = ' disabled="disabled"' if disabled && option_value_selected?(value, disabled)
      options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}#{disabled_attribute}#{html_attributes}>#{html_escape(text.to_s)}</option>)
    end

    options_for_select.join("\n").html_safe
  end

  def option_text_and_value(option)
    # Options are [text, value] pairs or strings used for both.
    case
    when Array === option
      option = option.reject { |e| Hash === e }
      [option.first, option.last]
    when !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
      [option.first, option.last]
    else
      [option, option]
    end
  end

  def option_html_attributes(element)
    return "" unless Array === element
    html_attributes = []
    element.select { |e| Hash === e }.reduce({}, :merge).each do |k, v|
      html_attributes << " #{k}=\"#{ERB::Util.html_escape(v.to_s)}\""
    end
    html_attributes.join
  end
end
