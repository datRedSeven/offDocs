class RemoveImageFileSizeFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :image_file_size, :integer
  end
end
