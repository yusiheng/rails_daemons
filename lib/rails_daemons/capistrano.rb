require 'capistrano/version'

if defined?(Capistrano::Version) && Gem::Version.new(Capistrano::Version).release < Gem::Version.new("3.0")
  raise "RailsDaemons requires Capistrano 3.x"
end

load File.expand_path("../tasks/rails_daemons.cap", __FILE__)