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
              process_queues[p_name] ||= {concurrency: 0, busy: 0, processes: 0}
              process_queues[p_name][:concurrency] += p['concurrency']
              process_queues[p_name][:busy] += p['busy']
              process_queues[p_name][:processes] += 1
            end
          end
          @queue_data = []
          @queue_names = []
          Sidekiq::Queue.all.each do |queue|
            next unless process_queues[queue.name]
            @queue_names << queue.name
            @queue_data << {name: queue.name, size: queue.size, concurrency: process_queues[queue.name][:concurrency], busy: process_queues[queue.name][:busy], paused: queue.paused?}
          end
          @versions = []
          process_queues.each do |p_name, p_data|
            next if p_name.to_s.match?("bot") || @queue_names.include?(p_name)
            @versions << {name: p_name, processes: p_data[:processes], concurrency: p_data[:concurrency], busy: p_data[:busy]}
          end

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

