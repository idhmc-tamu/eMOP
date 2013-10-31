
# Describes an eMOP work.
#
class Work < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :works
   self.primary_key = :wks_work_id
   has_many :pages, :foreign_key => :pg_work_id

   def isECCO?
      if !self.wks_ecco_number.nil? && self.wks_ecco_number.length > 0
         return true
      end
      return false
   end
end