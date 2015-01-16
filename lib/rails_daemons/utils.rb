module RailsDaemons
  module Utils
    extend self

    def join( *paths )
      # TODO: remove this dirty code
      return Rails.root.join( *paths ) if Rails.root.to_s !~ /.*\/releases\/\d{14}/
      
      paths = [ '..', '..', 'current' ] + paths
  
      path = Rails.root.join( *paths )
      FileUtils.mkdir_p( File.dirname( path ) )
      path
    end

    def logger( file_name )
      logger = Logger.new( join( 'log', file_name ) )
      logger.level = Logger::INFO
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      logger.formatter = Logger::Formatter.new

      logger
    end
  end
end