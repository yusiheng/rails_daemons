# RailsDaemons

Background workers for Rails. The gem is designed to safely handling exceptions occured in workers. Daemons restarts gracefully to achieve zerro downtime. RailsDaemons includes [Capistrano](https://github.com/capistrano/capistrano) and [Monit](https://mmonit.com/monit/) support. The gem also supports logrotate by safely handling signal USR1.

## Installation

Add this line to your application's Gemfile:

    gem 'rails_daemons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_daemons

## Capistrano integration
    
Add ```require 'rails_daemons/capistrano'``` to Capfile

This will get available commands:

```
  cap production daemon:start[<worker_name>]
  cap production daemon:restart[<worker_name>]
  cap production daemon:stop[<worker_name>]
```

## Background worker controls
    
```
  bundle exec daemon start <worker_name>
  bundle exec daemon restart <worker_name>
  bundle exec daemon stop <worker_name>
```

## Worker construction

Create background worker.

```ruby
  class ParserWorker
    include RailsDaemons::Worker

    def work
      # your work here
    end
  end
```

Also you can specify:

  * ```tick``` - delay between daemon cycles (in seconds, default 1.0)
  * ```start``` - work that should be done once on the daemon`s start (and restart)
  * ```shutdown``` - work that should be done before the daemon`s stop (either on exception or regular stop)

Example usage (with Mongoid):

  ```ruby
    # app/models/parsing.rb
    class Parsing
      include Mongoid::Document

      field :url
      field :state, default: 'pending'

      scope :pending, ->() { where( state: 'pending' ) }
      scope :running, ->() { where( state: 'running' ) }

      class << self
        def start
          [ 'http://www.example.com' ].each do |url|
            create!( url: url )
          end
        end
      end

      def process( logger ) 
        set( state: 'running' )

        # do the job

      rescue => e
        logger.info e.inspect
        
        set( state: 'halted' )
      end
    end

    # app/daemons/parser_worker.rb
    class ParserWorker
      include RailsDaemons::Worker

      def tick
        3 # in seconds
      end

      # daemon start
      def start
        require 'mechanize'
        require 'rufus-scheduler'

        scheduler = Rufus::Scheduler.new

        scheduler.every '12h' do
          Parsing.start # create parsing jobs every 12 hours
        end
      end

      # main work
      def work
        Parsing.pending.each do |parsing|
          t = Thread.new do
            parsing.process( $logger )
          end

          # exceptions handled in method ```process``` (just for an example)
          t.abort_on_exception = false
        end
      end

      # stop the daemon
      def shutdown
        Parsing.running.each do |parsing|
          parsing.set( state: 'stopped' )
        end
      end
    end  

  ```

## Monit integration:

Put the following code to /etc/init.d/<worker_name>, replace <worker_name> with you name.

```
#!/bin/bash
### BEGIN INIT INFO
# Provides:          <worker_name>
# Required-Start:    $all
# Required-Stop:     $network $local_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot
# Description:       Enable daemon at boot time.
### END INIT INFO

set -u
set -e

# Change these to match your app:
APP_NAME=app
ENV=production
USER=user
APP_ROOT="/home/$USER/$APP_NAME/current"

SET_PATH="cd $APP_ROOT; rvm use `cat $APP_ROOT/.ruby-version`@`cat $APP_ROOT/.ruby-gemset`"
OUT=">> $APP_ROOT/log/worker_name.$ENV.monit.log 2>&1"

cd $APP_ROOT || exit 1

case ${1-help} in
start)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec daemon start <worker_name> $OUT"
  ;;
stop)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec daemon stop <worker_name> $OUT"
  ;;
restart|reload)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec daemon restart <worker_name> $OUT"
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart>"
  exit 1
  ;;
esac 
```

Monit task:

```
check process <worker_name> with pidfile /<path_to_project>/current/tmp/pids/<worker_name>.production.pid
  start program = "/etc/init.d/<worker_name> start"
  stop program = "/etc/init.d/<worker_name> stop"
  if changed pid for 3 times within 5 cycles then restart
  if 5 restarts within 5 cycles then timeout
```

## Logrotate integration

```
/<path_to_project>/shared/log/*.log
{
        su <user> <group>
        daily
        missingok
        rotate 360
        compress
        delaycompress
        notifempty
    dateext
        create 0660 <user> <group>
        postrotate
                [ ! -f /<path_to_project>/shared/tmp/pids/unicorn.pid ] || kill -USR1 `cat /<path_to_project>/shared/tmp/pids/unicorn.pid`
                [ ! -f /<path_to_project>/shared/tmp/pids/<worker_name>.production.pid ] || kill -USR1 `cat /<path_to_project>/shared/tmp/pids/<worker_name>.production.pid`
        endscript
}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
