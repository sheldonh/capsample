set :application, "capsample"
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

#set :user, "sheldonh"
set :use_sudo, false

desc "Creates empty directories not tracked by git"
task :before_finalize_update, :roles => :web do
  [ File.join("public", "stylesheets") ].each do |empty_dir|
    full_path = File.join(current_release, empty_dir)
    run "mkdir -p #{current_release}/#{empty_dir}"
  end
end

