class CreateJuxtaCollations < ActiveRecord::Migration
  def change
    create_table :juxta_collations do |t|
      t.integer :page_result_id
      t.integer :jx_gt_source_id
      t.integer :jx_ocr_source_id
      t.integer :jx_set_id
      t.timestamps
    end
  end
end
