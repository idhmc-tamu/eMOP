
class FontsController < ApplicationController
   # Create a training font from the multipart form post
   #
   def create_training_font
      begin
         font_name = params["font-name"]
         if Font.where(:font_name=>font_name).count > 0 
            render :text => "A font with this name already exists. Please use a unique name.", :status => :error  
            return 
         end
         
         # grab the uploaded file and write it out
         # to the shared fonts directory
         upload_file = params[:file].tempfile
         orig_name =  params[:file].original_filename
         
         out = "#{Settings.emop_font_dir}/#{font_name}.traineddata"
         File.open(out, "wb") { |f| f.write(upload_file.read) }
         
         # Create a reference to it in the fonts tabls
         font = Font.new
         font.font_library_path = nil
         font.font_name = font_name
         font.save!

         # send back the new font as a json object so it can
         # be added to the relevant dropdown lists
         render :json => ActiveSupport::JSON.encode(font), :status => :ok
      rescue => e
         render :text => e.message, :status => :error
      end
   end
   
      
   # Set the print font on the works contained in th ePOST payload
   #
   def set_print_font
      begin 
         if params.has_key?(:new_font)
            pf = PrintFont.new
            pf.pf_name = params[:new_font]
            pf.save!
            font_id = pf.pf_id
         else
            font_id = params[:font_id]
            if font_id.length == 0
               font_id=nil
            end
         end
        
         works = params[:works].gsub(/\"/,'')
         works = works.gsub( /\[/, '(').gsub( /\]/, ')')
         sql = "update works set wks_primary_print_font=#{ActiveRecord::Base.sanitize(font_id)} where wks_work_id in #{works}"
         PrintFont.connection.execute( sql)
         render :text => "ok", :status => :ok
      rescue => e
         render :text => e.message, :status => :error
      end 
   end
end
