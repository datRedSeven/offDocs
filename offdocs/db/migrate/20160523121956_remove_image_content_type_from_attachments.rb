class RemoveImageContentTypeFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :image_content_type, :string
  end
end
