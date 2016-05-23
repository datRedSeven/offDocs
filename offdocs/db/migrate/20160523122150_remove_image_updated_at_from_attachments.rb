class RemoveImageUpdatedAtFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :image_updated_at, :datetime
  end
end
