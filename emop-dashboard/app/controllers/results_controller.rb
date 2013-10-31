require 'RMagick'

class ResultsController < ApplicationController
   # show the page details for the specified work
   #
   def show
      @work_id = params[:work]
      @batch_id = params[:batch]
      work = Work.find(@work_id)
      @work_title=work.wks_title
      
      if !@batch_id.nil?
         batch = BatchJob.find(@batch_id)
         @batch = "#{batch.id}: #{batch.name}"
      else 
         @batch = "Not Applicable"   
      end
      
      if !work.wks_primary_print_font.nil?
         pf = PrintFont.find(work.wks_primary_print_font)
         @print_font = pf.pf_name
      else
         @print_font = "Not Set"
      end
   end

   # Fetch data for dataTable
   #
   def fetch
      puts params
      
      work_id = params[:work]
      batch_id = params[:batch]
      if batch_id.nil? || batch_id.length == 0
         render_page_info(work_id)
      else
         render_batch_results(work_id, batch_id)
      end
   end
   
   # Render pages table without batch results
   #
   def render_page_info(work_id)
      resp = {}
      resp['sEcho'] = params[:sEcho]
      
      sql = ["select count(*) as cnt from pages where pg_work_id=?"]
      sql = sql << work_id
      cnt = PageResult.find_by_sql(sql).first.cnt
      resp['iTotalRecords'] = cnt
      resp['iTotalDisplayRecords'] = resp['iTotalRecords']
     
      # only order by page number here.. thats all thats available
      dir = params[:sSortDir_0]
      dir = "asc" if dir.nil?
      order_col = "pg_ref_number"
      
      sql = ["select pg_ref_number as page_num, pg_page_id as page_id from pages where pg_work_id=?", work_id]
      pages = Page.find_by_sql(sql)
      
      # get results and transform them into req'd json structure
      data = []
      pages.each do | page |
         rec = {}
         rec[:page_select] = "<input class='sel-cb' type='checkbox' id='sel-page-#{page.page_id}'>"
         rec[:detail_link] = "<div class='detail-link disabled'>"  # no details yet!
         rec[:ocr_text] = "<div class='ocr-txt  disabled' title='View OCR text output'>"
         rec[:ocr_hocr] = "<div class='ocr-hocr  disabled' title='View hOCR output'>"
         rec[:status] = page_status_icon(page.page_id, nil, nil)
         rec[:page_number] = page.page_num
         rec[:juxta_accuracy] = "-"
         rec[:retas_accuracy] = "-"
         rec[:page_image] = "<a href=\"/results/#{work_id}/page/#{page.page_num}\"><div title='View page image' class='page-view'></div></a>"

         data << rec
      end
      
      resp['data'] = data
      render :json => resp, :status => :ok    
   end
   
   # Render the pages table including batch results
   #
   def render_batch_results(work_id, batch_id)
      resp = {}
      resp['sEcho'] = params[:sEcho]
      
      sql = ["select count(*) as cnt from page_results inner join pages on page_id=pg_page_id where batch_id=? and pg_work_id=?"]
      sql = sql << batch_id
      sql = sql << work_id
      resp['iTotalRecords'] = PageResult.find_by_sql(sql).first.cnt
      resp['iTotalDisplayRecords'] = resp['iTotalRecords']
     
      # generate order info based on params
      search_col_idx = params[:iSortCol_0].to_i
      cols = [nil,'pg_ref_number','page_results.juxta_change_index','page_results.alt_change_index']
      dir = params[:sSortDir_0]
      dir = "asc" if dir.nil?
      order_col = cols[search_col_idx]
      order_col = cols[1] if order_col.nil?
      
      # get results and transform them into req'd json structure
      data = []
      sel =  "select pages.pg_ref_number as page_num,pages.pg_page_id as page_id,"
      sel << " page_results.id as result_id, page_results.juxta_change_index as juxta,"
      sel << " page_results.alt_change_index as retas, job_status"
      from =  "FROM pages"
      from << " inner join job_queue on job_queue.page_id=pages.pg_page_id"
      from << " left outer JOIN page_results ON page_results.page_id = pages.pg_page_id and page_results.batch_id=?"
      cond = "where job_queue.batch_id=? and pg_work_id=?"
      order = "order by #{order_col} #{dir}"
      sql = ["#{sel} #{from} #{cond} #{order}", batch_id, batch_id, work_id]
      pages = Page.find_by_sql( sql )
      msg = "View side-by-side comparison with GT"
      pages.each do | page | 
         rec = {}
         rec[:page_select] = "<input class='sel-cb' type='checkbox' id='sel-page-#{page.page_id}'>"
         rec[:ocr_text] = "<div id='result-#{page.result_id}' class='ocr-txt' title='View OCR text output'>" 
         rec[:ocr_hocr] = "<div id='hocr-#{page.result_id}' class='ocr-hocr' title='View hOCR output'>"
         if page.juxta.nil?
            rec[:juxta_accuracy] = "-"
            rec[:retas_accuracy] = "-"
            rec[:detail_link] = "<div class='juxta-link disabled'>"  # no details yet!
         else
            rec[:juxta_accuracy] = page.juxta
            rec[:retas_accuracy] = page.retas
            rec[:detail_link] = "<a href='/juxta?work=#{work_id}&batch=#{batch_id}&page=#{page.page_num}&result=#{ page.result_id}' title='#{msg}'><div class='juxta-link'></div></a>"
         end
         rec[:status] = page_status_icon(page.page_id, batch_id, page.job_status.to_i)
         rec[:page_number] = page.page_num
         rec[:page_image] = "<a href=\"/results/#{work_id}/page/#{page.page_num}\"><div title='View page image' class='page-view'></div></a>"

         data << rec
      end
      
      resp['data'] = data
      render :json => resp, :status => :ok
   end
   
   # Get the OCR text result for the specified page_result
   #
   def get_page_text
      page_id = params[:id]
      sql = ["select pg_ref_number, ocr_text_path from page_results inner join pages on pg_page_id=page_id where id=?",page_id]
      page_result = PageResult.find_by_sql( sql ).first
      txt_path = "#{Settings.emop_path_prefix}#{page_result.ocr_text_path}"
      file = File.open(txt_path, "r")
      contents = file.read
     
      if params.has_key?(:download)
         token = params[:token]
         inf = txt_path.split(/\//)
         send_data(contents, :filename=>inf[inf.length-1],  :type => "text/plain", :disposition => "attachment")
         cookies[:fileDownloadToken] = { :value => "#{token}", :expires => Time.now + 5}
       else
         resp = {}
         resp[:page] = page_result.pg_ref_number
         resp[:content] = contents
         render  :json => resp, :status => :ok  
      end
   end
   
   # Get the hOCR for the specified page_result
   #
   def get_page_hocr
      page_id = params[:id]
      sql = ["select pg_ref_number, ocr_xml_path from page_results inner join pages on pg_page_id=page_id where id=?",page_id]
      page_result = PageResult.find_by_sql( sql ).first
      xml_path = "#{Settings.emop_path_prefix}#{page_result.ocr_xml_path}"
      file = File.open(xml_path, "r")
      contents = file.read
      if params.has_key?(:download)
         token = params[:token]
         inf = xml_path.split(/\//)
         send_data(contents, :filename=>inf[inf.length-1],  :type => "text/xml", :disposition => "attachment")
         cookies[:fileDownloadToken] = { :value => "#{token}", :expires => Time.now + 5}
      else
         resp = {}
         resp[:page] = page_result.pg_ref_number
         resp[:content] = contents
         render  :json => resp, :status => :ok
      end
   end
   
   # Get the error for a page
   #
   def get_page_error
      page_id = params[:page]
      batch_id = params[:batch]
      sql = ["select pg_ref_number, results from job_queue inner join pages on pg_page_id=page_id where page_id=? and batch_id=?",page_id,batch_id]
      job = JobQueue.find_by_sql( sql ).first
      out = {}
      out[:page] = job.pg_ref_number
      out[:error] = job.results
      render  :json => out, :status => :ok     
   end
   
   # Reschedule failed page
   #
   def reschedule
      begin
         pages = params[:pages]
         batch_id = params[:batch]
         pages.each do | page_id |
            job = JobQueue.where("batch_id=? and page_id=?", batch_id, page_id).first 
            job.job_status=1;
            job.results = nil
            job.last_update = Time.now
            job.save!
            PageResult.where("batch_id=? and page_id=?", batch_id, page_id).destroy_all() 
         end
         render :text => "ok", :status => :ok
      rescue => e
         render :text => e.message, :status => :error
      end       
   end
   
   # Create a new batch from json data in the POST payload
   #
   def create_batch
      begin
         # create the new batch
         batch = BatchJob.new
         batch.name = params[:name]
         batch.job_type = params[:type_id]
         batch.ocr_engine_id = params[:engine_id]
         batch.font_id = params[:font_id]
         batch.parameters = params[:params]
         batch.notes = params[:notes]
         batch.save!
         
         # populate it with pages from the selected works
         # payload: {work: id, pages: [pageId,pageId...]}
         json_payload = ActiveSupport::JSON.decode(params[:json])
         work_id = json_payload['work']
         json_payload['pages'].each do | page_id |   
            job = JobQueue.new
            job.batch_id = batch.id
            job.page_id = page_id 
            job.job_status = 1  
            job.work_id = work_id
            job.save!
         end
         
         render  :text => batch.id, :status => :ok  
         
      rescue => e
         render :text => e.message, :status => :error
      end 
   end
   
   # Get TIFF page image, convert it to PNG and stream it back to client
   #
   def get_page_image
      work_id = params[:work]
      page_num = params[:num]   
      work = Work.find(work_id)
      img_path = get_ocr_image_path(work, page_num)
      img = Magick::Image::read(img_path).first
      img.format = 'PNG'
      send_data img.to_blob, :type => "image/png", :disposition => "inline", :x_sendfile=>true
   end
   
   private
   def page_status_icon( page_id, batch_id, job_status )
      if job_status.nil?
         if batch_id.nil?
            sql = ["select job_status from job_queue where page_id=?", page_id]
            res = JobQueue.find_by_sql(sql).first
            job_status = res.job_status if !res.nil?
         else
            sql = ["select job_status from job_queue where page_id=? and batch_id=?", page_id,batch_id]
            res = JobQueue.find_by_sql(sql).first
            job_status = res.job_status if !res.nil?
         end
      end
      
      status = "idle"
      msg = "Untested"
      id = nil
      if job_status ==1 || job_status ==2
         status = "scheduled"
         msg = "OCR job scheduled"  
      elsif job_status==6
         status = "error"
         msg = "OCR job failed"
         id = "id='status-#{batch_id}-#{page_id}'"
      elsif job_status == 3 || job_status == 4 || job_status == 5 
         status = "success"
         msg = "Success"
      end
      return "<div #{id} class='status-icon #{status}' title='#{msg}'></div>"
   end
   
   private
   def get_ocr_image_path(work, page_num) 
      
      # first, see if the image path was stored in DB. If so, use it
      page = Page.where("pg_work_id=? and pg_ref_number=?", work.wks_work_id, page_num).first
      if !page.nil? && !page.pg_image_path.blank?
         return "#{Settings.emop_path_prefix}#{page.pg_image_path}"
      end
        
      # not in db; try to generate it
      if work.isECCO?
         # ECCO format: ECCO number + 4 digit page + 0.tif
         ecco_dir = work.wks_ecco_directory
         return "%s%s/%s%04d0.TIF" % [Settings.emop_path_prefix, ecco_dir, work.wks_ecco_number, page_num];
      else
         # EEBO format: 00014.000.001.tif where 00014 is the page number.
         # EEBO is a problem because of the last segment before .tif. It is some
         # kind of version info and can vary. Start with 0 and increase til 
         # a file is found.
         ebbo_dir = work.wks_eebo_directory
         version_num = 0
         begin 
            img_file = "%s%s/%05d.000.%03d.tif" % [Settings.emop_path_prefix, ebbo_dir, page_num, version_num];
            if File.exists?(img_file)
               return img_file
            end
            version_num = version_num+1
         end  while version_num < 100 
         return "";  # NOT FOUND!
      end
   end
   
  


end
