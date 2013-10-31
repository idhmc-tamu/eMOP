
class JobType < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :job_type
   self.primary_key = :id
end