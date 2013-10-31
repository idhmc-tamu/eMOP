require 'rest_client'

class JuxtaController < ApplicationController
   
   # show a juxta sbs view of the specified OCR result vs ground truth
   #
   def show
      @result_id = params[:result]
      @work_id = params[:work]
      @batch_id = params[:batch]
      work = Work.find(@work_id)
      @work_title = work.wks_title
      batch_job = BatchJob.find(@batch_id)
      @batch = "#{batch_job.id}: #{batch_job.name}"
      @page_num = params[:page]

      # see if a collation exists for this result vs GT
      collation = JuxtaCollation.where(:page_result_id => @result_id).first
      if collation.nil?
         # create a new collation if one doesn't exist.
         # status will be created
         collation = JuxtaCollation.new(:page_result_id => @result_id)
         collation.save!
      end

      # Create collation and load visualization
      begin
           
         # upload sources, create witnesses & sets and collate result      
         if collation.status == "error" || collation.status == "uninitialized"
            create_visualization( collation )   
         end
         
         # update the last accessed time
         collation.last_accessed = Time.now
         collation.save!
      
         # generate the visualization
         get_side_by_side_visualization(collation)
         
      rescue RestClient::Exception => rest_error
         collation.status = "error"
         collation.save!
         render :text => rest_error.response, :status => rest_error.http_code
      rescue Exception => e
         collation.status = "error"
         collation.save!
         render :text => e, :status => :internal_server_error
      end
   end

   # Create a new juxta collation
   #
   private
   def create_visualization(collation)
      if collation.status == "error"  
         reset_collation(params[:collation])      
      end
      
      result = PageResult.find( collation.page_result_id )
         
      # upload sources
      gt_file = result.page.pg_ground_truth_file
      ocr_file = result.ocr_text_path
      gt_id, ocr_id = create_jx_sources( gt_file, ocr_file)
      collation.jx_gt_source_id = gt_id
      collation.jx_ocr_source_id = ocr_id
      collation.save!

      # create witnesses
      gt_wit_id, ocr_wit_id = create_jx_witnesses( gt_id, gt_file, ocr_id, ocr_file )
      collation.jx_gt_witness_id = gt_wit_id
      collation.jx_ocr_witness_id = ocr_wit_id
      collation.save!
      
      # create a set with the witnesses, and set collation settings
      set_name = "#{@work_id}.#{@batch_id}.#{result.page.pg_ref_number}"
      set_id = create_jx_set(set_name, gt_wit_id, ocr_wit_id)
      collation.jx_set_id = set_id
      collation.save!
      
      # collate it
      query = "#{Settings.juxta_ws_url}/set/#{set_id}/collate"
      resp = RestClient.post query, '', :content_type => "application/json", :authorization => Settings.auth_token
      done = false
      query = "#{Settings.juxta_ws_url}/task/#{resp}/status"
      while done == false do
         sleep 1
         status = JSON.parse(RestClient.get query, :authorization => Settings.auth_token)
         done = (status['status'] == 'COMPLETE')
      end
      
      # bump status to ready and save it!
      collation.status = "ready"
      collation.save!
   end
   
   # get the side-by-side visualization of a GT vs OCR page
   #
   private
   def get_side_by_side_visualization(collation)
      @error = false
      @content = ""
      docs = "#{collation.jx_gt_witness_id},#{collation.jx_ocr_witness_id}"
      query = "#{Settings.juxta_ws_url}/set/#{collation.jx_set_id}/view?mode=sidebyside&docs=#{docs}&embed"
      begin
         @content = RestClient.get query, :authorization => Settings.auth_token, :accept => 'text/html'
         if @content.include? "RENDERING"
            task_id = @content.split(' ')[1]
            status_query = "#{Settings.juxta_ws_url}/task/#{task_id}/status"
            done = false
            while done == false do
               sleep 1
               status = JSON.parse(RestClient.get status_query, :authorization => Settings.auth_token)
               done = (status['status'] == 'COMPLETE')
            end
            @content = RestClient.get query, :authorization => Settings.auth_token, :accept => 'text/html'
         end
         
      rescue RestClient::Exception => rest_error
         @error = true
         @juxta_error_message = rest_error.response
      end
   end
   
   # delete all data associated with a collation and reset status
   # back to uninitalized
   #
   private 
   def reset_collation(collation)   
      # delete sources first
      begin
         jx_url = "#{Settings.juxta_ws_url}/source"
         RestClient.delete jx_url+"/#{collation.jx_gt_source_id}", :authorization => Settings.auth_token
         RestClient.delete jx_url+"/#{collation.jx_ocr_source_id}", :authorization => Settings.auth_token
         
         # next, delete set
         jx_url = "#{Settings.juxta_ws_url}/set"
         RestClient.delete jx_url+"/#{collation.jx_set_id}", :authorization => Settings.auth_token
      rescue RestClient::Exception => rest_error
         if rest_error.http_code != 404
            raise
         end
      end
      
      # last, reset the collation
      collation.jx_set_id = nil
      collation.jx_gt_source_id = nil
      collation.jx_ocr_source_id = nil
      collation.status = "uninitialized"
      collation.save!
   end

   # Create a jx comparison set with the witnesses
   #
   private
   def create_jx_set( name, gt_wit_id, ocr_wit_id) 
      jx_exist_url = "#{Settings.juxta_ws_url}/set/exist?name=#{name}"
      resp = RestClient.get jx_exist_url, :authorization => Settings.auth_token
      json_resp = ActiveSupport::JSON.decode( resp )
      if json_resp['exists'] 
         return json_resp['id']
      end
      
      jx_set_query = "#{Settings.juxta_ws_url}/set"
      data = {}
      data['name'] = name
      data['witnesses'] = [gt_wit_id, ocr_wit_id]
      json_data = ActiveSupport::JSON.encode( data )
      resp = RestClient.post jx_set_query, json_data, :content_type => "application/json", :authorization => Settings.auth_token
      set_id = resp.gsub(/\"/, "")
      
      # now set the collator settings
      data = { :filterWhitespace=>true, :filterPunctuation=>true,:filterCase=>true,:hyphenationFilter=>"FILTER_ALL" }
      json_data = ActiveSupport::JSON.encode( data )
      jx_set_query = "#{Settings.juxta_ws_url}/set/#{set_id}/collator"
      RestClient.post jx_set_query, json_data, :content_type => "application/json", :authorization => Settings.auth_token
   
      return set_id
   end

   # Transform sources into witnesses. Returns [GT witnessID, OCR witnessID]
   #
   private
   def create_jx_witnesses(gt_src_id, gt_file, ocr_src_id, ocr_file)
      gt_name = gt_file.gsub( /.txt/, '' )
      ocr_name = ocr_file.gsub( /.txt/, '' )
      jx_xform_query = "#{Settings.juxta_ws_url}/transform"
      jx_exist_url = "#{Settings.juxta_ws_url}/witness/exist?name="
      data = {}
      
      # witness for GT source
      resp = RestClient.get jx_exist_url+gt_name, :authorization => Settings.auth_token
      json_resp = ActiveSupport::JSON.decode( resp )
      if json_resp['exists'] 
         gt_id = json_resp['id']
      else
         data['source'] = gt_src_id
         data['finalName'] = gt_name
         json_data = ActiveSupport::JSON.encode( data )
         resp = RestClient.post jx_xform_query, json_data, :content_type => "application/json", :authorization => Settings.auth_token
         gt_id =  resp.gsub( /\"/, "" )
      end
      
      # witness for OCR source
      resp = RestClient.get jx_exist_url+ocr_name, :authorization => Settings.auth_token
      json_resp = ActiveSupport::JSON.decode( resp )
      if json_resp['exists'] 
         ocr_id = json_resp['id']
      else
         data['source'] = ocr_src_id
         data['finalName'] = ocr_name
         json_data = ActiveSupport::JSON.encode( data )
         resp = RestClient.post jx_xform_query, json_data, :content_type => "application/json", :authorization => Settings.auth_token
         ocr_id =  resp.gsub( /\"/, "" )
      end
      
      return gt_id, ocr_id
   end

   # upload the GT and OCR sources to JuxtaWS. Returns [GT sourceID, OCR sourceD]
   #
   private
   def create_jx_sources(gt_file, ocr_file)
      data = {}
      data['type'] = "raw"
      data['contentType'] = "txt"
      jx_exist_url = "#{Settings.juxta_ws_url}/source/exist?name="
      jx_url = "#{Settings.juxta_ws_url}/source"
      
      # handle GT source first
      resp = RestClient.get jx_exist_url+gt_file, :authorization => Settings.auth_token
      json_resp = ActiveSupport::JSON.decode( resp )
      if json_resp['exists'] 
         gt_id = json_resp['id']
      else
         data['name'] = gt_file
         data['data'] = File.read("#{Settings.emop_path_prefix}#{gt_file}")
         json_data = ActiveSupport::JSON.encode( [ data ] )
         resp = RestClient.post jx_url, json_data, :content_type => "application/json", :authorization => Settings.auth_token
         json_resp = ActiveSupport::JSON.decode( resp )
         gt_id = json_resp[0]    
      end
      
      # now OCR source
      resp = RestClient.get jx_exist_url+ocr_file, :authorization => Settings.auth_token
      json_resp = ActiveSupport::JSON.decode( resp )
      if json_resp['exists'] 
         ocr_id = json_resp['id']
      else
         data['name'] = ocr_file
         data['data'] = File.read("#{Settings.emop_path_prefix}#{ocr_file}")
         json_data = ActiveSupport::JSON.encode( [ data ] )
         resp = RestClient.post jx_url, json_data, :content_type => "application/json", :authorization => Settings.auth_token
         json_resp = ActiveSupport::JSON.decode( resp )
         ocr_id = json_resp[0]    
      end
   
      return gt_id, ocr_id
   end
end
