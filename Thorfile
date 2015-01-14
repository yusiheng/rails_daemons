unless defined? Thor::Runner
  require 'bundler'

  gems = Bundler::Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil).requested_specs

  gem = gems.find { |gem| gem.name == 'thor' }

  load "#{ENV['GEM_HOME']}/gems/#{gem.name}-#{gem.version}/bin/thor"
end

Dir.glob("lib/rails_daemons/tasks/*.thor") do |name|
  Thor::Util.load_thorfile(name)
end