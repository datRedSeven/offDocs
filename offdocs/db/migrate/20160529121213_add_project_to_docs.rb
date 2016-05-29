class AddProjectToDocs < ActiveRecord::Migration
  def change
    add_column :docs, :project, :boolean, default: false
  end
end
