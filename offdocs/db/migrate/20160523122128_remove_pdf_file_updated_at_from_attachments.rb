class RemovePdfFileUpdatedAtFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :pdf_file_updated_at, :datetime
  end
end
