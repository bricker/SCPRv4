set :application, 'scprv4'
set :scm, :git
set :repo_url, 'git@github.com:SCPR/SCPRv4.git'

set :linked_files, [
  "config/database.yml",
  "config/api_config.yml",
  "config/app_config.yml",
  "config/thinking_sphinx.yml",
  "config/newrelic.yml"
]

set :maintenance_template_path, "public/maintenance.erb"
set :maintenance_basename, "maintenance"

set :format, :pretty
set :log_level, :debug


namespace :deploy do
  desc "Put up a maintenance page"
  namespace :web do
    task :disable do
      on roles(:app) do
        basename = fetch(:maintenance_basename)
        template = fetch(:maintenance_template_path)

        require 'erb'
        on_rollback { run "rm -f #{shared_path}/system/#{basename}.html" }

        reason    = ENV['REASON']
        deadline  = ENV['UNTIL']

        file    = File.read(template)
        result  = ERB.new(file).result(binding)

        put result, "#{shared_path}/system/#{basename}.html", :mode => 0644
      end
    end


    desc "Take down the maintenance page"
    task :enable do
      on roles(:app) do
        basename = fetch(:maintenance_basename)
        run "rm -f #{shared_path}/system/#{basename}.html"
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
    run_locally do
      if token = YAML.load_file(
        File.expand_path("../api_config.yml", __FILE__)
      )["production"]["kpcc"]["private"]["api_token"]
        data = {
          :token       => token,
          :user        => `whoami`.gsub("\n", ""),
          :datetime    => Time.now.strftime("%F %T"),
          :application => fetch(:application)
        }

        url = "http://www.scpr.org/api/private/v2/utility/notify"
        info "[deploy:notify] Sending notification to #{url}"

        begin
          Net::HTTP.post_form(URI.parse(URI.encode(url)), data)
        rescue Errno::ETIMEDOUT => e
          warn "[deploy:notify] Timed out while trying to notify. Moving on."
        end

      else
        warn "[deploy:notify] No API token specified. Moving on."
      end
    end
  end


  after :finishing, 'deploy:cleanup'
end
