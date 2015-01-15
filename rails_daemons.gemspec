# -*- encoding: utf-8 -*-
# stub: rails_daemons 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_daemons"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Sergey Malykh"]
  s.date = "2015-01-15"
  s.description = "Daemons for Rails. Can be restarted on the host by Thor or remotely by Capistrano, monitored by Monit"
  s.email = ["xronos.i.am@gmail.com"]
  s.files = [".gitignore", ".ruby-gemset", ".ruby-version", "Capfile", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "Thorfile", "lib/rails_daemons.rb", "lib/rails_daemons/capistano.rb", "lib/rails_daemons/railtie.rb", "lib/rails_daemons/tasks.cap", "lib/rails_daemons/tasks.rb", "lib/rails_daemons/version.rb", "lib/rails_daemons/worker.rb", "rails_daemons.gemspec"]
  s.homepage = "https://github.com/xronos-i-am/rails_daemons"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.4"
  s.summary = "Daemons for Rails"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<capistrano>, ["~> 3.3"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_runtime_dependency(%q<unicorn>, [">= 0"])
      s.add_runtime_dependency(%q<thor-rails>, [">= 0"])
    else
      s.add_dependency(%q<capistrano>, ["~> 3.3"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<unicorn>, [">= 0"])
      s.add_dependency(%q<thor-rails>, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>, ["~> 3.3"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<unicorn>, [">= 0"])
    s.add_dependency(%q<thor-rails>, [">= 0"])
  end
end
