# To deploy:
# cap menu

require 'rvm/capistrano'
require 'bundler/capistrano'

# Read in the site-specific information so that the initializers can take advantage of it.
config_file = "config/cap.yml"
if File.exists?(config_file)
   set :site_specific, YAML.load_file(config_file)['capistrano']
else
   puts "***"
   puts "*** Failed to load capistrano configuration. Did you create #{config_file} with a capistrano section?"
   puts "***"
end

set :repository, "git@github.com:performant-software/emop-dashboard.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache

set :use_sudo, false

set :normalize_asset_timestamps, false

set :rails_env, "production"

#set :whenever_command, "bundle exec whenever"

def set_application(section)
   set :deploy_to, "#{site_specific[section]['deploy_base']}"
   set :application, site_specific[section]['ssh_name']
   set :user, site_specific[section]['user']
   set :rvm_ruby_string, site_specific[section]['ruby']
   if site_specific[section]['system_rvm']
      set :rvm_type, :system
   end

   role :web, "#{application}"                          # Your HTTP server, Apache/etc
   role :app, "#{application}"                          # This may be the same as your `Web` server
   role :db,  "#{application}", :primary => true      # This is where Rails migrations will run
end

desc "Print out a menu of all the options that a user probably wants."
task :menu do
   tasks = {
      '1' => { name: "cap edge", computer: 'edge' },
      '2' => { name: "cap production", computer: 'prod' }
   }

   tasks.each { |key, value|
      puts "#{key}. #{value[:name]}"
   }

   print "Choose deployment type: "
   begin
      system("stty raw -echo")
      option = STDIN.getc
   ensure
      system("stty -raw echo")
   end
   puts ""

   value = tasks[option]
   if !value.nil?
      set_application(value[:computer])
      puts "Deploying..."
      after :menu, 'deploy'
   else
      puts "Not deploying. Please enter a value from the menu."
   end
end

desc "Run tasks in edge environment."
task :edge do
   set_application('edge')
end

desc "Run tasks in production environment."
task :production do
   set_application('prod')
end

namespace :passenger do
   desc "Restart Application"
   task :restart do
      run "touch #{current_path}/tmp/restart.txt"
   end
end

namespace :config do
   desc "Config Symlinks"
   task :symlinks do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
   end
end

after :edge, 'deploy'
after :production, 'deploy'
#after :deploy, "deploy:migrate"
after "deploy:finalize_update", "config:symlinks"
after :deploy, "passenger:restart"

reset = "\033[0m"
green = "\033[32m" # Green
red = "\033[31m" # Bright Red

desc "Set up the edge  emop-dashboard server."
task :edge_setup do
   set_application('edge')
end
after :edge_setup, 'deploy:setup'

desc "Set up the production emop-dashboard server."
task :prod_setup do
   set_application('prod')
end
after :prod_setup, 'deploy:setup'

desc "Set up the edge server's config."
task :setup_config do
   run "mkdir #{shared_path}/config"
   run "touch #{shared_path}/config/database.yml"
   puts ""
   puts "#{red}!!!"
   puts "!!! Now create the database.yml file in the shared folder on the server."
   puts "!!! Also create the database in mysql."
   puts "!!!#{reset}"
end

after 'deploy:setup', :setup_config
