class DashboardController < ApplicationController
   # main dashboard summary view
   #
   def index
      # pull extra filter data from session 
      @batch_filter = session[:batch]
      @set_filter = session[:set]
      @from_filter = session[:from]
      @to_filter = session[:to]
      @ocr_filter = session[:ocr]
      @gt_filter = session[:gt]
      @print_font_filter = session[:font]
       
      # get summary for queue
      @queue_status = get_job_queue_status()
   end
   
   # Get an HTML fragment for the batch details tooltip
   #
   def batch      
      @batch = BatchJob.find( params[:id] )
      @job_type = JobType.find( @batch.job_type )
      @ocr_engine = OcrEngine.find( @batch.ocr_engine_id )
      @font = @batch.font
      out = render_to_string( :partial => 'batch_tooltip', :layout => false )
      render :text => out.strip
   end

   # Called from datatable to fetch a subset of data for display
   #
   def fetch
      # NOTE: have sample data from TCP K072
      puts params
      resp = {}
      resp['sEcho'] = params[:sEcho]
      resp['iTotalRecords'] = Work.count()
      
      # generate order info based on params
      search_col_idx = params[:iSortCol_0].to_i
      cols = [nil,nil,nil,nil,'wks_work_id',
              'wks_tcp_number','wks_title','wks_author',
              'work_ocr_results.ocr_completed','work_ocr_results.ocr_engine_id',
              'work_ocr_results.batch_id','work_ocr_results.juxta_accuracy',
              'work_ocr_results.retas_accuracy']
      dir = params[:sSortDir_0]
      order_col = cols[search_col_idx]
      order_col = cols[4] if order_col.nil?

      # stuff filter params in session so they can be restored each view
      session[:search] = params[:sSearch]
      session[:gt] = params[:gt]
      session[:batch]  = params[:batch]
      session[:set] = params[:set]
      session[:from] = params[:from]
      session[:to] = params[:to]
      session[:ocr]  = params[:ocr]
      session[:font]  = params[:font]
      
      # generate the select, conditional and vars parts of the query
      # the true parameter indicates that this result should include
      # all columns necessry to populate the dashboard view.
      sel, where_clause, vals = generate_query()

      # build the ugly query
      limits = "limit #{params[:iDisplayLength]} OFFSET #{params[:iDisplayStart]}"
      order = "order by #{order_col} #{dir}"
      if session[:ocr] == 'ocr_sched'
         # scheduled uses a different query that needs a group by to make the results work
         sql = ["#{sel} #{where_clause} group by work_id, batch_id #{order} #{limits}"]   
      else
         sql = ["#{sel} #{where_clause} #{order} #{limits}"]   
      end
      
      sql = sql + vals

      # get all of the results (paged)
      results = WorkOcrResult.find_by_sql(sql)
      
      # run a count query without the paging limits to get
      # the total number of results available
      pf_join = "left outer join print_fonts on pf_id=wks_primary_print_font"
      if session[:ocr] == 'ocr_sched'
         # search for scheduled uses different query to get data. Also need slightly
         # differnent query to get counts
         count_sel = "select count(distinct batch_id) as cnt from works #{pf_join} inner join job_queue on wks_work_id=job_queue.work_id "
      else
         count_sel = "select count(*) as cnt from works  #{pf_join} left outer join work_ocr_results on wks_work_id=work_id "
      end
      sql = ["#{count_sel} #{where_clause}"]
      sql = sql + vals
      filtered_cnt = Work.find_by_sql(sql).first.cnt
      
      # jam it all into an array of objects that match teh dataTables structure
      data = []
      results.each do |result|
         rec = result_to_hash(result)   
         data << rec 
      end
            
      resp['data'] = data
      resp['iTotalDisplayRecords'] = filtered_cnt
      render :json => resp, :status => :ok
   end
   
   # Get errors for a work
   #
   def get_work_errors
      work_id = params[:work]
      batch_id = params[:batch]
      query = "select pg_ref_number, results from job_queue "
      query = query << " inner join pages on pg_page_id=page_id"
      query = query << " where job_status=? and batch_id=? and work_id=?"
      sql = [query, 6,batch_id,work_id]
      page_errors = JobQueue.find_by_sql( sql )
      out = {}
      out[:work] = work_id
      out[:job] = BatchJob.find(batch_id).name
      out_errors = []
      page_errors.each do | err |
         out_errors << {:page=>err.pg_ref_number, :error=>err.results}
      end
      out[:errors] = out_errors
      render  :json => out, :status => :ok
   end
   
   # Reschedule failed batch
   #
   def reschedule 
      begin
         # job info is passed down as a json string. String
         # is an array of objects. Each object has work and batch.
         # Decode the string and handle the request
         jobs = ActiveSupport::JSON.decode(params[:jobs])
         jobs.each do | job |
            work_id = job['work']
            batch_id = job['batch']
            
            # remove the page results
            sql = "delete from page_results where batch_id=#{batch_id} "
            sql = sql << " and page_id in (select pg_page_id from pages where pg_work_id=#{work_id})"
            PageResult.connection.execute( sql )
            
            # set job status back to scheduled
            sql = "update job_queue set job_status=1,results=NULL where batch_id=#{batch_id} and work_id=#{work_id}"
            JobQueue.connection.execute(sql);
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
         json_payload = ActiveSupport::JSON.decode(params[:json])
         json_payload['works'].each do | work_id |
            pages = Page.where("pg_work_id = ?", work_id)
            pages.each do | page |
               job = JobQueue.new
               job.batch_id = batch.id
               job.page_id = page.pg_page_id
               job.job_status = 1
               job.work_id=work_id
               job.save!
            end
         end

         # get a new summary for the job queue
         status = get_job_queue_status()
         render  :json => ActiveSupport::JSON.encode(status), :status => :ok  
         
      rescue => e
         render :text => e.message, :status => :error
      end 
   end

   private
   def fix_date_format ( src_date )
      bits = src_date.split("/")
      out = "#{bits[2]}-#{bits[0]}-#{bits[1]}"
      return out  
   end
   
   # Turn the activerecord data into a nice plan hash that jQuery dataTable can use
   #
   private
    def result_to_hash(result)
      rec = {}
      rec[:id] = result.work_id
      
      # the checkbox id is a combination of work and batch id.
      # if there is no batch, it is workId-0
      id = "#{result.work_id}-0" if result.batch_id.nil?
      id = "#{result.work_id}-#{result.batch_id}" if !result.batch_id.nil?
      rec[:work_select] = "<input class='sel-cb' type='checkbox' id='sel-#{id}'>"
      
      if result.batch_id.nil?
         rec[:detail_link] = "<a href='results?work=#{result.work_id}'><div class='detail-link' title='View pages'></div></a>"
      else
         rec[:detail_link] = "<a href='results?work=#{result.work_id}&batch=#{result.batch_id}'><div class='detail-link' title='View pages'></div></a>"
      end

      rec[:status] = get_status(result)

      if !result.ecco_number.nil? && result.ecco_number.length > 0
         rec[:data_set] = 'ECCO'
      else
         rec[:data_set] = 'EEBO'
      end
      
      rec[:tcp_number] = result.wks_tcp_number
      rec[:title] = result.title
      rec[:author] = result.author
      rec[:font] = result.font_name
      rec[:ocr_date] = nil
      rec[:ocr_engine] = nil
      rec[:ocr_batch] = nil
      rec[:juxta_url] = nil
      rec[:retas_url] = nil
      if !result.batch_id.nil? 
         rec[:ocr_date] = result.ocr_completed.to_datetime.strftime("%m/%d/%Y %H:%M") if result.has_attribute?(:ocr_completed)
         rec[:ocr_engine] = OcrEngine.find(result.ocr_engine_id ).name  if result.has_attribute?(:ocr_engine_id)
         rec[:ocr_batch] = "<span class='batch-name' id='batch-#{result.batch_id}'>#{result.batch_id}: #{result.batch_name}</span>"
         rec[:juxta_url] = gen_pages_link(result.work_id, result.batch_id, result.juxta_accuracy) if result.has_attribute?(:juxta_accuracy)
         rec[:retas_url] = gen_pages_link(result.work_id, result.batch_id, result.retas_accuracy) if result.has_attribute?(:retas_accuracy)
      end
      return rec
   end
   
   private
   def get_status(result)
      if result.batch_id.nil?
          sql=["select count(*) as cnt from job_queue where page_id in (select pg_page_id from pages where pg_work_id=?)",result.work_id] 
          cnt = JobQueue.find_by_sql(sql).first.cnt
          if cnt == 0
             return "<div class='status-icon idle' title='Untested'></div>"
          else
             return "<div class='status-icon scheduled' title='OCR jobs are scheduled'></div>"
          end
      end
      
      sql = ["select job_status from job_queue where batch_id=? and page_id in (select pg_page_id from pages where pg_work_id=?)",
         result.batch_id, result.work_id]
      jobs = JobQueue.find_by_sql(sql)
      status = "idle"
      msg = "Untested"
      id=nil
      jobs.each do |job|
         if job.job_status ==1 || job.job_status ==2
            if status != "error"
               status = "scheduled"
               msg = "OCR jobs are scheduled"   
            end
         end
         if job.job_status==6
            status = "error"
            msg = "OCR jobs have failed"
            id = "id='status-#{result.batch_id}-#{result.work_id}'"
            break
         end
         if job.job_status > 2 && job.job_status < 6
            if status != "error"
               status = "success"
               msg = "Success"
            end
         end
      end
      return "<div #{id} class='status-icon #{status}' title='#{msg}'></div>"
   end
   
  private

   def gen_pages_link(work_id, batch_id, accuracy)
      link_class = ""
      if accuracy.nil?
         out = "N/A"
      else
         if accuracy < 0.6
            link_class = "class='bad-cell'"
         elsif accuracy < 0.8
            link_class = "class='warn-cell'"
         end
         formatted = '%.3f'%accuracy
         out = "<a href='results?work=#{work_id}&batch=#{batch_id}' #{link_class} title='View page results'>#{formatted}</a>"
      end

      return out
   end
   
   private 
   def get_job_queue_status()
      summary = {}
      sql = ["select count(*) as cnt from job_queue where job_status=?"]
      sql = sql << 1
      summary[:pending] = JobQueue.find_by_sql(sql).first.cnt
      
      sql = ["select count(*) as cnt from job_queue where job_status=?"]
      sql = sql << 2
      summary[:running] = JobQueue.find_by_sql(sql).first.cnt
      
      sql = ["select count(*) as cnt from job_queue where job_status=?"]
      sql = sql << 3
      summary[:postprocess] = JobQueue.find_by_sql(sql).first.cnt
      
      sql = ["select count(*) as cnt from job_queue where job_status=?"]
      sql = sql << 6
      summary[:failed] = JobQueue.find_by_sql(sql).first.cnt
      return summary
   end
   
   # Create the monster select & where portion of the dashboard
   # results query. Use data in the session as filter.
   #
   private
   def generate_query( )
      # build where conditions
      q = session[:search]
      cond = ""
      vals = []
      if q.length > 0 
         cond = "(wks_work_id LIKE ? || wks_author LIKE ? || wks_title LIKE ?)"
         vals = ["%#{q}%", "%#{q}%", "%#{q}%" ]   
      end
      
      # add in extra filters:
      # NOTES: for ECCO, non-null TCP means GT is available
      #        for EEBO, non-null MARC means GT is avail
      if !session[:gt].nil?
         cond << " and" if cond.length > 0
         cond << " (wks_tcp_number is not null or wks_marc_record is not null)"
      end
      
      if !session[:batch].nil?
         cond << " and" if cond.length > 0
         cond << " batch_id=?"
         vals << session[:batch]
      end    
      
      if !session[:font].nil?
         cond << " and" if cond.length > 0
         cond << " pf_id=?"
         vals << session[:font]
      end    
      
      if !session[:set].nil?
         if session[:set] == 'EEBO'
            cond << " and" if cond.length > 0
            cond << " wks_ecco_number is null"
         elsif session[:set] == 'ECCO'
            cond << " and" if cond.length > 0
            cond << " wks_ecco_number is not null"
         end
      end
      
      if !session[:from].nil?
         cond << " and" if cond.length > 0
         cond << " work_ocr_results.ocr_completed > ?"
         vals << fix_date_format(session[:from])
      end
      if !session[:to].nil?
         cond << " and" if cond.length > 0
         cond << " work_ocr_results.ocr_completed < ?"
         vals << fix_date_format(session[:to])
      end
      
      if session[:ocr] == 'ocr_done'
         cond << " and" if cond.length > 0
         cond << " (select max(job_status) as js from job_queue where job_queue.batch_id=work_ocr_results.batch_id and job_queue.work_id=wks_work_id) in (3,4,5)"
         cond << " and (select min(job_status) as js from job_queue where  job_queue.batch_id=work_ocr_results.batch_id and job_queue.work_id=wks_work_id) > 2"
      elsif  session[:ocr] == 'ocr_sched'
         cond << " and" if cond.length > 0
         cond << " job_status < 3"
      elsif  session[:ocr] == 'ocr_none'
         cond << " and" if cond.length > 0
         cond << " work_ocr_results.ocr_completed is null"
      elsif session[:ocr] == 'ocr_error'
         cond << " and" if cond.length > 0
         cond << " (select max(job_status) as js from job_queue where job_queue.batch_id=work_ocr_results.batch_id and job_queue.work_id=wks_work_id)=6"
      end

      # build the ugly query to get all the info
      work_fields = "wks_work_id as work_id, wks_tcp_number, wks_title as title, wks_author as author, wks_ecco_number as ecco_number"
      if session[:ocr] == 'ocr_sched'
         # special query to get SCHEDULED works; dont use work_ocr_results
         v_fields = "pf_id, pf_name as font_name, batch_id, batch_job.name as batch_name, ocr_engine_id"
         sel = "select #{work_fields}, #{v_fields} from works left outer join print_fonts on pf_id=wks_primary_print_font"
         sel << " left outer join job_queue on wks_work_id=job_queue.work_id "
         sel << " inner join batch_job on batch_job.id = batch_id "
      else
         v_fields = "pf_id,pf_name as font_name, batch_id, ocr_completed, batch_name, ocr_engine_id, juxta_accuracy, retas_accuracy"
         sel = "select #{work_fields}, #{v_fields} from works left outer join work_ocr_results on wks_work_id=work_id"
         sel << " left outer join print_fonts on pf_id=wks_primary_print_font "
      end
      
      where_clause = ""
      where_clause = "where #{cond}" if cond.length > 0
      return sel, where_clause, vals
   end

end
