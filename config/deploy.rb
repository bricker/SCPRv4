set :application, 'scprv4'
set :scm, :git
set :repo_url, 'git@github.com:SCPR/SCPRv4.git'
set :branch, :master

set :deploy_to, "/web/scprv4"
set :ssh_options, {
  user: 'scprv4'
}


set :format, :pretty
set :log_level, :debug
# set :pty, true

set :linked_files, [
  "config/database.yml",
  "config/api_config.yml",
  "config/app_config.yml",
  "config/thinking_sphinx.yml",
  "config/newrelic.yml"
]


set :maintenance_template_path, "public/maintenance.erb"
set :maintenance_basename, "maintenance"

# Pass these in with -s to override: 
#    cap deploy -s force_assets=true
set :force_assets,  false # If assets wouldn't normally be precompiled, force them to be
set :skip_assets,   false # If assets are going to be precompiled, force them NOT to be
set :ts_index,      false # Staging only - Whether or not to run the sphinx index on drop
set :syncdb,        false # Staging only - Whether or not to run a dbsync to mercer_staging


namespace :deploy do

  desc "Put up a maintenance page"
  namespace :web do
    task :disable do
      on roles(:app) do

        require 'erb'
        on_rollback { run "rm -f #{shared_path}/system/#{maintenance_basename}.html" }

        reason    = ENV['REASON']
        deadline  = ENV['UNTIL']

        template = File.read(maintenance_template_path)
        result   = ERB.new(template).result(binding)

        put result, "#{shared_path}/system/#{maintenance_basename}.html", :mode => 0644
      end
    end


    desc "Take down the maintenance page"
    task :enable do
      on roles(:app) do
        run "rm -f #{shared_path}/system/#{maintenance_basename}.html"
      end
    end
  end


  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 60 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end


  task :notify do
    if token = YAML.load_file(
      File.expand_path("../../api_config.yml", __FILE__)
    )["production"]["kpcc"]["private"]["api_token"]
      data = {
        :token       => token,
        :user        => `whoami`.gsub("\n", ""),
        :datetime    => Time.now.strftime("%F %T"),
        :application => application
      }

      url = "http://www.scpr.org/api/private/v2/utility/notify"
      logger.info "Sending notification to #{url}"
      begin
        Net::HTTP.post_form(URI.parse(URI.encode(url)), data)
      rescue Errno::ETIMEDOUT => e
        logger.info "Timed out while trying to notify. Moving forward."
      end

    else
      logger.info "No API token specified. Moving on."
    end
  end


  after :finishing, 'deploy:cleanup'
end
