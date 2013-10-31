EmopDashboard::Application.routes.draw do
  # create a new training font
  post "fonts/training_font" => "fonts#create_training_font"
  post "fonts/print_font" => "fonts#set_print_font"

   # juxta visualization routes
   get "juxta" => "juxta#show"

   # page results routes
   get "results" => "results#show"
   get "results/:work/page/:num" => "results#get_page_image"
   get "results/fetch" => "results#fetch"
   post "results/batch" => "results#create_batch"
   get "results/:id/text" => "results#get_page_text"
   get "results/:id/hocr" => "results#get_page_hocr"
   get "results/:batch/:page/error" => "results#get_page_error"
   post "results/reschedule" => "results#reschedule"

   # main dashboard routes
   get "dashboard/index"
   get "dashboard/fetch"
   get "dashboard/batch/:id" => "dashboard#batch"
   post "dashboard/batch" => "dashboard#create_batch"
   post "dashboard/reschedule" => "dashboard#reschedule"
   get "dashboard/:batch/:work/error" => "dashboard#get_work_errors"

   # site root is the dashboard
   root :to => "dashboard#index"
end
