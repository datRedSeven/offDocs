class RemovePdfFileContentTypeFromAttachments < ActiveRecord::Migration
  def change
    remove_column :attachments, :pdf_file_content_type, :string
  end
end
