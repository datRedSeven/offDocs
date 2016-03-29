class Doc < ActiveRecord::Base
	def self.search(search)
		where("source ILIKE ?", "%#{search}%")
		where("title ILIKE ?", "%#{search}%")
	end
	belongs_to :user
end
