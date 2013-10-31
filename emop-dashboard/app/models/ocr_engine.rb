
class OcrEngine < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :ocr_engine
   self.primary_key = :id
end