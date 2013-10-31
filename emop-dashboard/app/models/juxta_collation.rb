require 'rest_client'

class JuxtaCollation < ActiveRecord::Base
   attr_accessible :page_result_id, :jx_gt_source_id, :jx_ocr_source_id, :jx_set_id, :status

   validates_inclusion_of :status, :in => ['uninitialized', 'ready', 'error', :uninitialized, :ready, :error]
   
   def self.expire_old_sets()
      expire_hrs = Settings.juxta_expire_hrs
      secs = expire_hrs.to_i * 60 *60
      old = JuxtaCollation.find(:all, :conditions => ["last_accessed < ?", Time.now - secs] )
      del_gt_list = []
      old.each do | jx |
         
         # can't delete GT sources immediately; they may be used in other sets
         # accumulate a list of them and only delete later if it is 
         # determined that they are not in any other sets
         del_gt_list << jx.jx_gt_source_id
         
         logger.info "Delete OCR source #{jx.jx_ocr_source_id}"
         query = "#{Settings.juxta_ws_url}/source/#{jx.jx_ocr_source_id}"
         RestClient.delete query, :authorization => Settings.auth_token
         
         logger.info "Delete set #{jx.jx_set_id}"
         query = "#{Settings.juxta_ws_url}/set/#{jx.jx_set_id}"
         RestClient.delete query, :authorization => Settings.auth_token
         
         logger.info "Delete record #{jx.id}"
         JuxtaCollation.destroy_all( :id => jx.id )
      end
      
      # see if the GT sources are used in other sets?
      del_gt_list.each do | gt_id |
         cnt =  JuxtaCollation.count(:conditions=>["jx_gt_source_id=?", gt_id])
         if cnt == 0
             logger.info "Delete GT source #{gt_id}"
            query = "#{Settings.juxta_ws_url}/source/#{gt_id}"
            RestClient.delete query, :authorization => Settings.auth_token
         else
            logger.info "NOT deleting GT source #{gt_id}; in-use by other sets"
         end
      end
   end
end
