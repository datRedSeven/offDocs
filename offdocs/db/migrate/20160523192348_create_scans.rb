class CreateScans < ActiveRecord::Migration
  def change
    create_table :scans do |t|
      t.integer :attachment_id

      t.timestamps null: false
    end
  end
end
