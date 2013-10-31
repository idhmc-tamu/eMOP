class AddLastAccessedToJuxtaCollations < ActiveRecord::Migration
  def change
     add_column :juxta_collations, :last_accessed, :datetime, :default => 0
  end
end
