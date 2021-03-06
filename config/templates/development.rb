##
# This is just a template, so we can keep `development.rb`
# out of version control. It contains the configuration
# necessary for SCPRv4 to run properly in development,
# and sets some sensible defaults.
#
# COPY this file to `config/environments/development.rb`
# and modify as needed.
# The repository's `.gitignore` is already set to ignore
# `config/environments/development.rb`.
#
# The following paths will need to be modified for your machine:
#   * config.scpr.media_root
#   * config.scpr.media_url
#
# You'll also need to create a `dbsync` directory at the same
# directory level as the SCPRv4 application directory, or otherwise
# modify the `config.dbsync.local_dir` configuration.
#
Scprv4::Application.configure do
  config.cache_classes  = false
  config.eager_load     = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :redis_content_store, "redis://localhost:6379/5"
  config.action_controller.action_on_unpermitted_parameters = :raise

  config.assets.debug         = false  # Expand
  config.serve_static_assets  = true  # Serve from public/
  config.assets.compile       = true  # Fallback
  config.assets.digest        = false # Add asset fingerprints

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Gmail
  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings         = {
    :address              => 'smtp.gmail.com',
    :port                 => 587,
    :domain               => 'kpcc.org',
    :user_name            => 'kpccdev@gmail.com',
    :password             => '',
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }

  config.dbsync = {
    :local   => "#{Rails.root}/../dbdumps/mercer.dump",
    :remote  => "scprdb@66.226.4.229:~scprdb/mercer.dump"
  }

  default_url_options[:host] = "localhost:3000"

  config.scpr.host         = "localhost:3000"
  config.scpr.media_root   = "/Users/bricker/media"
  config.scpr.media_url    = "http://media.scpr.org"
  # If you need to test uploading/serving files locally,
  # start a Rack server from the `media_root` directory:
  #
  #   ruby -run -e httpd /Users/bricker/media/ -p 5000
  #
  # Then you can use this configuration:
  # config.scpr.media_url    = "http://localhost:5000"

  # Job queue namespace.
  config.scpr.resque_queue = :scprv4

  config.node.server = "http://localhost:8888"
end
