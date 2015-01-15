require 'thor/rails'

module RailsDaemons
  class Daemon < Thor
    include Thor::Rails
    namespace :daemon

    no_commands do
      def get_daemon( name )
        RailsDaemons.qualified_const_get( name.camelize )
      rescue NameError => e
        puts "Unknown daemon '#{name}'"
      end
    end

    desc "start <worker_name>", "Start background worker"
    def start( name )
      daemon = get_daemon( name )
      return if daemon.nil?
      daemon.new.daemonize
    end

    desc "restart <worker_name>", "Restart background worker (alias for start command)"
    def restart( name )
      invoke :start, [ name ]
    end

    desc "stop <worker_name>", "Stop background worker"
    def stop( name )
      get_daemon( name ).stop
    end
  end
end