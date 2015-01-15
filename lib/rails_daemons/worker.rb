require 'rails_daemons/utils'
require 'unicorn/util'
require 'active_support/concern'

module RailsDaemons
  module Worker
    extend ActiveSupport::Concern

    included do 
      def daemonize
        pid = fork do
          $logger = Utils.logger( "#{self.class.worker_name}.#{Rails.env}.log" )
          $logger.level = Logger::INFO

          working
        end

        Process.detach( pid )

        puts "#{self.class.worker_name} (#{pid}) started."
      end

      def working
        $stop_working = false
        $reopening = false

        Signal.trap "INT" do
          Thread.new do
            shutdowning
          end
        end

        Signal.trap "USR1" do
          $reopening = true
        end

        stop_old_worker

        starting

        loop do
          reopen_logs if $reopening
          break if $stop_working

          work

          sleep tick
        end
      end

      def reopen_logs
        pid = self.class.get_pid

        logger.info "Reopen logs #{self.class.worker_name} (#{pid})"

        Unicorn::Util.reopen_logs

        logger.info "Logs reopened #{self.class.worker_name} (#{pid})"

        $reopening = false
      end

      def logger
        $logger
      end

      def starting
        $0 = "RAILS_ENV=#{Rails.env} " + Utils.join( '' ).to_s + " bundle exec thor daemon:start #{self.class}"

        redirect_io
        start
        store_pid
      end

      def redirect_io
        # https://github.com/ghazel/daemons/blob/d09e132ea67001ba4d6bf6481fb53c4bd4fd9195/lib/daemons/daemonize.rb#L241
        begin; STDIN.reopen "/dev/null"; rescue ::Exception; end

        begin
          STDOUT.reopen( Utils.join( 'log', "#{self.class.worker_name}.#{Rails.env}.out.log" ), "a" )
          STDOUT.sync = true
        rescue ::Exception
          begin; STDOUT.reopen "/dev/null"; rescue ::Exception; end
        end

        begin; STDERR.reopen STDOUT; rescue ::Exception; end
        STDERR.sync = true
      end

      def start
        puts "Start #{self.class.name}"
      end

      def work
        raise 'Not implemented! Write your own work'
      end

      def tick
        1.0
      end

      def shutdowning
        pid = self.class.get_pid

        logger.info "Graceful shutdown #{self.class.worker_name} (#{pid})"
        $stop_working = true

        shutdown

        puts "#{self.class.worker_name} (#{pid}) stopped."

        exit 0

      rescue => e
        logger.error "exiting #{self.class.worker_name}, unable to stop gracefully"
        logger.error e.message
        logger.error e.backtrace.join( "\n" )

        File.remove( self.class.pid_file ) if File.exists?( self.class.pid_file )

        exit 1
      end

      def shutdown
      end

      def stop_old_worker
        return unless File.file?( self.class.pid_file )

        pid = self.class.get_pid

        unless self.class.running?( pid )
          logger.info "Stale pid file (#{pid}), deleting"
          File.delete( self.class.pid_file )

          return
        end

        logger.info "Killing old worker (#{pid})"
        Process.kill( "INT", pid )

        # wait for die
        32.times do
          sleep 3

          unless self.class.running?( pid )
            logger.info "Old worker (#{pid}) died by himself"

            return
          end
        end

        return unless self.class.running?( pid )

        logger.error "Old worker (#{pid}) isn't going to die, doing kill -9"

        Process.kill( "KILL", pid )
        File.delete( self.class.pid_file )
      end

      def store_pid
        FileUtils.mkdir_p( File.dirname( self.class.pid_file ) )
        IO.write( self.class.pid_file, Process.pid.to_s )
      end
    end

    module ClassMethods
      def daemonize
        self.new.daemonize
      end

      def stop
        pid = get_pid

        if running?( pid )
          Process.kill( 'INT', pid )
        else
          puts "Worker #{name} (#{pid}) not running"
        end
      end

      def get_pid
        return unless File.exists?( pid_file )
        File.read( pid_file ).to_i
      end

      def pid_file
        Utils.join( 'tmp', 'pids', "#{worker_name}.#{Rails.env}.pid" )
      end

      def worker_name
        name.underscore
      end

      def running?( pid )
        return false if pid.blank?

        # https://github.com/ghazel/daemons/blob/d09e132ea67001ba4d6bf6481fb53c4bd4fd9195/lib/daemons/pid.rb#L17
        # Check if process is in existence
        # The simplest way to do this is to send signal '0'
        # (which is a single system call) that doesn't actually
        # send a signal
        begin
          Process.kill(0, pid)
          return true
        rescue Errno::ESRCH
          return false
        rescue ::Exception # for example on EPERM (process exists but does not belong to us)
          return true
        end
      end
    end
  end
end