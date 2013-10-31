
# Describes a results of a job run on a page
#
class PageResult < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :page_results
   belongs_to :page
   
   # get the type of ocr engine used to generate this result
   #
   def get_ocr_engine
      batch_job = BatchJob.find( self.batch_id )
      ocr_id = batch_job.ocr_engine_id
      return :gale if ocr_id == 1   
      return :tesseract if ocr_id == 2
      return :gamera if ocr_id == 3
      return :ocropus if ocr_id == 4
      return :none
   end
end