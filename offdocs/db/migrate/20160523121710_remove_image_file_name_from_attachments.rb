class RemoveImageFileNameFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :image_file_name, :string
  end
end
