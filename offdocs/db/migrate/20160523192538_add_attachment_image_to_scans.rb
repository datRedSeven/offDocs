class AddAttachmentImageToScans < ActiveRecord::Migration
  def self.up
    change_table :scans do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :scans, :image
  end
end
