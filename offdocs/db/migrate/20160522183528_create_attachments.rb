class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer :doc_id

      t.timestamps null: false
    end
  end
end
