set :application, "capsample"
set :scm, :git
set :repository,  "git://github.com/sheldonh/capsample.git"
set :deploy_via, :remote_cache # Does a git pull instead of a full repo fetch

role :app, "lenny.vmware"
role :web, "lenny.vmware"
role :db,  "lenny.vmware", :primary => true

set :app_server, :passenger

#set :user, "sheldonh"
set :use_sudo, false

set :deployment, "beta" unless exists?(:deployment)
load File.join(File.dirname(__FILE__), "deployments", deployment)

set :shared_db_dir, File.join(deploy_to, shared_dir, "db")

namespace :deploy do
  if "sqlite3" == database_adapter.to_s
    desc "Create shared db directory for sqlite3."
    task :after_setup, :roles => :db do
      run "mkdir -p #{shared_db_dir}"
    end

    desc "Handle shared sqlite3 databases."
    task :before_finalize_update, :roles => [ :web, :db ] do
      [ "development", "test", "production" ].each do |db|
        link_name = File.join(current_release, "db", "#{db}.sqlite3")
        link_to = File.join(shared_db_dir, "#{db}.sqlite3")
        parallel do |session|
          session.when "in?(:db)", "ln -s #{link_to} #{link_name}"
        end
      end
    end
  end

  if "passenger" == app_server.to_s
    desc "Requests a Phusion Passenger restart."
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end

    [ :start, :stop ].each do |override_task|
      desc "Does nothing with Phusion Passenger."
      task override_task, :roles => :app do
      end
    end
  end
end
