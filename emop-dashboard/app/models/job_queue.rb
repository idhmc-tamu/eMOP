
# Describes the emop job queue
#
class JobQueue < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :job_queue
   self.primary_key = :id   
end