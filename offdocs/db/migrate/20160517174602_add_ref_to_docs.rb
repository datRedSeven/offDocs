class AddRefToDocs < ActiveRecord::Migration
  def change
  	add_column :docs, :original_id, :integer
    add_index :docs, :original_id
  end
end
