Scprv4::Application.configure do
  config.cache_classes  = true
  config.eager_load     = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store = :redis_content_store, "redis://10.226.4.234:6379/7"
  # config.cache_store = :redis_content_store, "redis://localhost:6379/5"
  config.action_controller.action_on_unpermitted_parameters = :log

  config.assets.debug         = false
  config.serve_static_assets  = false
  config.assets.digest        = true
  config.assets.compile       = false

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Enable Postmark for transactional mail sending
  config.action_mailer.delivery_method          = :postmark
  config.action_mailer.raise_delivery_errors    = true
  config.action_mailer.postmark_settings = {
    :api_key => config.api['postmark']['api_key']
  }


  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  default_url_options[:host] = "www.scpr.org"

  config.scpr.host         = "www.scpr.org"
  config.scpr.media_root   = "/home/kpcc/media"
  config.scpr.media_url    = "http://media.scpr.org"
  config.scpr.resque_queue = :scprv4

  config.node.server = "http://node.scprdev.org"
end
