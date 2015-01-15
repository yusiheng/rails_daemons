lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_daemons/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_daemons"
  spec.version       = RailsDaemons::VERSION
  spec.authors       = ["Sergey Malykh"]
  spec.email         = ["xronos.i.am@gmail.com"]
  spec.description   = %q{Daemons for Rails. Can be restarted on the host by Thor or remotely by Capistrano, monitored by Monit}
  spec.summary       = %q{Daemons for Rails}
  spec.homepage      = "https://github.com/xronos-i-am/rails_daemons"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "capistrano", '~> 3.3'
  spec.add_development_dependency "bundler"

  spec.add_dependency "unicorn"
  spec.add_dependency "thor-rails"
end
