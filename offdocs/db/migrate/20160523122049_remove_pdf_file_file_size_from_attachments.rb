class RemovePdfFileFileSizeFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :pdf_file_file_size, :integer
  end
end
