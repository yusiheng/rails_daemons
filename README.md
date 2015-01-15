# RailsDaemons

[Visit GitHub!](www.github.com)

Advanced daemons for Rails. Can be controlled by [Thor](https://github.com/erikhuda/thor) on the host or remotely by [Capistrano](https://github.com/capistrano/capistrano). Can be monitored and automatically restarted by [Monit](https://mmonit.com/monit/). When daemon restarts the new worker hasn't started till the old one is gracefully shutdowned. Supports USR1 signal sent by logrotate.

## Installation

Add this line to your application's Gemfile:

    gem 'rails_daemons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_daemons

Capistrano integration:
    
    Add ```require 'rails_daemons/capistrano'``` to Capfile

    This will get available commands:

    ```
      cap production daemon:start[ParserWorker]
      cap production daemon:restart[ParserWorker]
      cap production daemon:stop[ParserWorker]

Thor tasks:
    
    Add ```require 'rails_daemons/thor'``` to Thorfile (create in root app path if not exists)

    This will get available commands:

    ```
      thor daemon:start ParserWorker
      thor daemon:restart ParserWorker
      thor daemon:stop ParserWorker

## Usage

  Create daemon worker. It should have atleast one method: 
  
    * ```work``` - main work that should be done by daemon

Also you can specify:

  * ```tick``` - delay between daemon cycles (in seconds)
  * ```start``` - work that should be done on the daemon`s start
  * ```shutdown``` - work that should be done before the daemon`s stop (ie, store raised error to database)

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
    class ParserWorker < RailsDaemons::Worker
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

Service script:

```
#!/bin/bash
### BEGIN INIT INFO
# Provides:          parser_worker
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
OUT=">> $APP_ROOT/log/parser_worker.$ENV.monit.log 2>&1"

cd $APP_ROOT || exit 1

case ${1-help} in
start)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec thor daemon:start ParserWorker $OUT"
  ;;
stop)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec thor daemon:stop ParserWorker $OUT"
  ;;
restart|reload)
  su - $USER -c "$SET_PATH; RAILS_ENV=$ENV bundle exec thor daemon:restart ParserWorker $OUT"
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart>"
  exit 1
  ;;
esac 
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
