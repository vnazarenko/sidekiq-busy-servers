module Sidekiq
  module BusyServers
    module WebExtension
      ROOT = File.expand_path('../../../../web', __FILE__)

      def self.registered(app)
        app.get '/busy_servers' do
          render(:erb, File.read("#{ROOT}/views/busy_servers.erb"))
        end

        app.post '/busy_servers' do
          if params['identity']
            p = Sidekiq::Process.new('identity' => params['identity'])
            p.quiet! if params['quiet']
            p.stop! if params['stop']
          else
            processes.each do |pro|
              pro.quiet! if params['quiet']
              pro.stop! if params['stop']
            end
          end

          redirect "#{root_path}busy_servers"
        end

        app.settings.locales << File.expand_path('locales', ROOT)
      end
    end
  end
end

