require 'settingslogic'

# settingsLogic model to expose settings from emop.yml
# to the eMOP dashboard app
#
class Settings < Settingslogic
  source "#{Rails.root}/config/emop.yml"
  namespace Rails.env
  load!
  
  def self.auth_token
    return "Basic "+Base64.encode64("#{Settings.juxta_ws_user}:#{Settings.juxta_ws_pass}")
  end
end