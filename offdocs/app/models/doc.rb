class Doc < ActiveRecord::Base
	acts_as_votable
	belongs_to :user
	has_many :updates, class_name: "Doc", foreign_key: "original_id"
	belongs_to :original, class_name: "Doc"
	has_many :attachments, :dependent => :destroy
	

	searchable do
		text :title
		text :document
		text :source
		date :date_published
		
	end
end
