class AddSubscriptionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscription, :integer
  end
end
