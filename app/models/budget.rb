class Budget < ActiveRecord::Base
	has_many :causes
	belongs_to :user
	attr_accessible :type, :to, :from, :value, :name,
                  :participants_count, :creation_date, :city,
                  :initiator, :reason, :decision, :evaluation,
                  :recomendation, :edit_number, :locked

	def self.inheritance_column
		nil
	end

	def author
		self.user ? self.user.name : "Brak przypisanego autora"
	end
end
