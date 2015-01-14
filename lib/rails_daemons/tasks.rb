require 'thor/rails'

class Daemons < Thor
  include Thor::Rails

  no_commands do
    def get_daemon( name )
      RailsDaemons.qualified_const_get( name.camelize )
    rescue NameError => e
      puts "Unknown daemon '#{name}'"
    end
  end

  desc "start <daemon>", "Start background worker"
  def start( name )
    daemon = get_daemon( name )
    return if daemon.nil?
    daemon.new.daemonize
  end

  desc "restart <daemon>", "Restart background worker (alias for start command)"
  def restart( name )
    invoke :start, [ name ]
  end

  desc "stop <daemon>", "Stop background worker"
  def stop( name )
    get_daemon( name ).stop
  end
end