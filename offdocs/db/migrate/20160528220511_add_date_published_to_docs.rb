class AddDatePublishedToDocs < ActiveRecord::Migration
  def change
    add_column :docs, :date_published, :date
  end
end
