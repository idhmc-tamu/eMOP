class ApplicationController < ActionController::Base
   protect_from_forgery
   before_filter :get_dropdown_data
   
   def get_dropdown_data
      raw_batches = BatchJob.all()
      @job_types = JobType.all()
      @engines = OcrEngine.all()
      @fonts = Font.all()
      @print_fonts = PrintFont.all()

      @batches = []
      raw_batches.each do |batch|
         foo = {}
         foo[:id] = batch.id
         foo[:name] = batch.name
         foo[:parameters] = batch.parameters
         foo[:notes] = batch.notes
         foo[:type] = @job_types[batch.job_type-1]
         foo[:engine] = @engines[batch.ocr_engine_id-1]
         foo[:font] = batch.font
         @batches << foo
      end
   end
end
