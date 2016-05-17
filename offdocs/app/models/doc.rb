class Doc < ActiveRecord::Base
	belongs_to :user
	has_many :updates, class_name: "Doc", foreign_key: "original_id"
	belongs_to :original, class_name: "Doc"
	has_attached_file :attachment, :path => ':rails_root/downloads/:id.pdf'

	searchable do
		text :document, :title
	end
end
