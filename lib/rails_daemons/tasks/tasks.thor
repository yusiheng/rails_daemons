require 'thor/rails'

class Daemons < Thor
  include Thor::Rails

  desc "start [<daemon_class_name> or 'all']", "Start background worker"
  def start( what = 'all' )
    RailsDaemons.daemons.each do |worker|
      worker.new.daemonize if what == 'all' || what == worker.name
    end
  end

  desc "restart [<daemon_class_name> or 'all']", "Restart background worker (alias for start command)"
  def restart( what = 'all' )
    invoke :start, [ what ]
  end

  desc "stop [<daemon_class_name> or 'all']", "Stop background worker"
  def stop( what = 'all' )
    RailsDaemons.daemons.each do |worker|
      worker.stop if what == 'all' || what == worker.name
    end
  end
end