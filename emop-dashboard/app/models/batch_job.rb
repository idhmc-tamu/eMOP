
# Describes an eMOP batch job
#
class BatchJob < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :batch_job
   self.primary_key = :id   
   belongs_to :font
end