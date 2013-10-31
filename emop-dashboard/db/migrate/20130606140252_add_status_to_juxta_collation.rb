class AddStatusToJuxtaCollation < ActiveRecord::Migration
  def change
     add_column :juxta_collations, :status, "ENUM('uninitialized', 'ready', 'error')", :default => :uninitialized
  end
end
