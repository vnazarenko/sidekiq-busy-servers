require 'sidekiq/web'
require 'sidekiq/busy_servers/version'
require 'sidekiq/busy_servers/web_extension'

Sidekiq::Web.register(Sidekiq::BusyServers::WebExtension)

if Sidekiq::Web.tabs.is_a?(Array)
  # For sidekiq < 2.5
  Sidekiq::Web.tabs << 'busy_servers'
else
  Sidekiq::Web.tabs['BusyServers'] = 'busy_servers'
end
