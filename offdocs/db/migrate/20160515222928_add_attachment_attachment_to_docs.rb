class AddAttachmentAttachmentToDocs < ActiveRecord::Migration
  def self.up
    change_table :docs do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :docs, :attachment
  end
end
