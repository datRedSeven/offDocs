class RemovePdfFileFileNameFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :pdf_file_file_name, :string
  end
end
