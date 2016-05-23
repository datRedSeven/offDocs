class Scan < ActiveRecord::Base
	belongs_to :attachment
	has_attached_file :image, :path => ":rails_root/app/assets/images/:filename", :url => ":filename"
end
