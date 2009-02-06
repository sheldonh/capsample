set :application, "capsample"
set :rails_env, "development"
set :repository,  "git://github.com/sheldonh/capsample.git"
set :deploy_via, :remote_cache # Does a git pull instead of a full repo fetch

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

role :app, "lenny.vmware"
role :web, "lenny.vmware"
role :db,  "lenny.vmware", :primary => true

set :app_server, :passenger

#set :user, "sheldonh"
set :use_sudo, false

set :shared_db_dir, File.join(deploy_to, shared_dir, "db")

namespace :deploy do
  desc "Create shared db directory for sqlite3."
  task :after_setup, :roles => :db do
    run "mkdir -p #{shared_db_dir}"
  end

  desc "Handle directories not tracked by git, and shared sqlite3 databases."
  task :before_finalize_update, :roles => [ :web, :db ] do
    [ File.join("public", "stylesheets") ].each do |missing_dir|
      full_path = File.join(current_release, missing_dir)
      parallel do |session|
        session.when "in?(:web)", "mkdir -p #{current_release}/#{missing_dir}"
      end
    end

    [ File.join(current_release, "db") ].each do |missing_dir|
      parallel do |session|
        session.when "in?(:db)", "mkdir -p #{missing_dir}"
      end
    end

    [ "development", "test", "production" ].each do |db|
      link_name = File.join(current_release, "db", "#{db}.sqlite3")
      link_to = File.join(shared_db_dir, "#{db}.sqlite3")
      parallel do |session|
        session.when "in?(:db)", "ln -s #{link_to} #{link_name}"
      end
    end
  end

  if [ :passenger ].include?(app_server)
    desc "Requests a Phusion Passenger restart."
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end
  end
end
