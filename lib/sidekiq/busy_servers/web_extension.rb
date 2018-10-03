module Sidekiq
  module BusyServers
    module WebExtension
      ROOT = File.expand_path('../../../../web', __FILE__)

      def self.registered(app)
        app.get '/busy_servers' do
          process_queues = {}
          @processes = processes
          @processes.each do |p|
            p['queues'].each do |p_name|
              process_queues[p_name] ||= {concurrency: 0, busy: 0}
              process_queues[p_name][:concurrency] += p['concurrency']
              process_queues[p_name][:busy] += p['busy']
            end
          end
          @queue_data = []
          Sidekiq::Queue.all.each do |queue|
            next unless process_queues[queue.name]
            @queue_data << {name: queue.name, concurrency: process_queues[queue.name][:concurrency], busy: process_queues[queue.name][:busy], paused: queue.paused?}
          end
          puts @queue_data.inspect

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

