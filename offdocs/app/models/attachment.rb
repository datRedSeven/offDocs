class Attachment < ActiveRecord::Base
	belongs_to :doc
	has_attached_file :file, :path => ":rails_root/downloads/:filename"
	has_many :scans, :dependent => :destroy

end
