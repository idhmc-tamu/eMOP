class AddWitnessesToJuxtaCollations < ActiveRecord::Migration
  def change
      add_column :juxta_collations, :jx_gt_witness_id, :integer
      add_column :juxta_collations, :jx_ocr_witness_id, :integer
  end
end
