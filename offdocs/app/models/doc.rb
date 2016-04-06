class Doc < ActiveRecord::Base
	belongs_to :user

	searchable do
		text :title, :source, :document
	end
end
