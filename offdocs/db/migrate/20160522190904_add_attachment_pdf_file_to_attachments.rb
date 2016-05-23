class AddAttachmentPdfFileToAttachments < ActiveRecord::Migration
  def self.up
    change_table :attachments do |t|
      t.attachment :pdf_file
    end
  end

  def self.down
    remove_attachment :attachments, :pdf_file
  end
end
