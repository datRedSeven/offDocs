class CreateDocs < ActiveRecord::Migration
  def change
    create_table :docs do |t|
      t.string :title
      t.string :source
      t.string :source_link
      t.text :document
      t.string :url

      t.timestamps null: false
    end
  end
end
