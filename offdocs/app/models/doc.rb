class Doc < ActiveRecord::Base
	belongs_to :user
	has_attached_file :attachment, :path => ':rails_root/downloads/:id.pdf'

	searchable do
		text :title, :source, :document
	end
end
