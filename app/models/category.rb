class Category < ActiveRecord::Base
  belongs_to :parent, :class_name => "Category", :foreign_key => "category_id"
  has_many :causes
  mount_uploader :marker, MarkerUploader
end
