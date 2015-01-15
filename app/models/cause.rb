#require 'ruport/acts_as_reportable'

class Cause < ActiveRecord::Base
  acts_as_taggable_on :tags
  acts_as_reportable
  
  has_many :rich_contents
  
  belongs_to :category
  belongs_to :user
  belongs_to :budget
  after_save :clean_images
  
  validates_presence_of :author
  validates_presence_of :title
  validates_presence_of :local
  validates_presence_of :latitude
  validates_presence_of :longitude
  validates_presence_of :abstract

  named_scope :by_city, lambda {|city| {:conditions => {:city => city}, :order => "updated_at DESC" } }
  named_scope :by_budget, lambda {|name| {:joins => :budget, :conditions => ["budget.name = ?", name], :order => "updated_at DESC" } }

  def accepted?
    !self.is_rejected
  end

  def rejected?
    self.is_rejected
  end

  def undecided?
    self.is_rejected.nil?
  end

  def self.search(text, category)
    text = "%#{text}%"
    filter_category = category.blank? ? "" : "and category_id=#{category}"
     self.find(:all, 
    :conditions => ["is_rejected = 0 and submited = 1 and ( title like :text or author like :text or abstract like :text or local like :text or district like :text) #{filter_category}",{:text => text}],
    :order => "updated_at DESC")
  end

  def self.search_by_city_and_budget_name(phrase, category)
    phrase = "%#{phrase}%"
    filter_category = category.blank? ? "" : "and category_id=#{category}"
    self.find(:all, 
      :joins => :budget,
      :conditions => ["is_rejected = 0 and 
        submited = 1 and
        (city like :phrase or budgets.name like :phrase)
        #{filter_category}",
      {:phrase => phrase}],
    :order => "updated_at DESC")
  end
  
  def self.search_ext(phrase, category)
    phrase = "%#{phrase}%"
    filter_category = category.blank? ? "" : "and category_id=#{category}"
    self.find(:all,
      :joins => :budget,
      :conditions => ["is_rejected = 0 and
        submited = 1 and
        (title like :phrase or author like :phrase or abstract like :phrase or local like :phrase or district like :phrase or city like :phrase or budgets.name like :phrase)
        #{filter_category}",
      {:phrase => phrase}],
    :order => "updated_at DESC")
  end

  def related_causes
    Cause.find(:all,
    :select => "id, title, category_id", 
    :conditions => ["category_id = #{self.category_id} and id <> '#{self.id}' and is_rejected = 0 and submited = 1"],
    :order => "updated_at DESC",
    :limit => 3)
  end
  
  def same_neighborhood_causes
    Cause.find(:all,
    :select => "id, title, category_id", 
    :conditions => ["district = '#{self.district}' and id <> '#{self.id}' and is_rejected = 0 and submited = 1"],
    :order => "updated_at DESC",
    :limit => 3)
  end
  
  def self.find_causes_by_latitude_and_longitude(map_position, cats, budget)
    causes = self.where("is_rejected = 0 and submited = 1")
    causes = causes.where(["latitude between ? and ? and longitude between ? and ?", map_position[:latB], map_position[:latA], map_position[:lngB], map_position[:lngA]])

    if cats
      causes = causes.where(["category_id not in (?)", cats])
    end

    if not budget.empty?
      causes = causes.where(["budget_id = ?", budget])
    end

    causes.find(:all,
        :select => "id, title, category_id, latitude, longitude, views, updated_at",
        :include => :category,
        :order => "views DESC, updated_at DESC"
    )
  end
  
  def url
    "/causas/#{category.name.to_slug}/#{title.to_slug}/#{id}"
  end
  
  def absolute_url
   "http://portoalegre.cc#{self.url}"
  end

  def clean_images
    RichContent.destroy_all(:cause_id => self.id, :choosen => 0, :kind => 1)
  end

  def get_falapoa_data
    response = ActiveSupport::JSON.decode(RestClient.get("#{APP_CONFIG["falapoa_address"]}/#{self.protocol}"))
    
    if response["status"] == "success"
      response["data"]["last_update"] = created_at if response["data"].keys.include?("last_update") && response["data"]["last_update"].nil?
      response["data"]
    else
      { "status" => response["message"] }
    end
  end

  def send_to_falapoa(user, cause_url, reference)
    cause_hash = {
      :local => self.local,
      :district => self.district,
      :abstract => "[Ponto de Referência: #{reference}] - #{self.abstract}",
      :url => cause_url
    }
    user_hash = { :name => user.name, :email => user.email }
    data = { :cause => cause_hash, :user => user_hash }
    begin
      response = RestClient.post("#{APP_CONFIG["falapoa_address"]}/send", data)
      if response
        decoded_response = ActiveSupport::JSON.decode(response)
        self.update_attribute(:protocol, decoded_response["data"]) if decoded_response["status"] == "success"
      end
    rescue
    end
  end

end