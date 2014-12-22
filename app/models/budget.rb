class Budget < ActiveRecord::Base
	has_many :causes
	belongs_to :user
	attr_accessible :type, :to, :from, :value, :name, :participants_count

	def self.inheritance_column
		nil
	end

	def author
		self.user ? self.user.name : "Brak przypisanego autora"
	end
end
