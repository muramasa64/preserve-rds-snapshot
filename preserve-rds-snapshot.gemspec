# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'preserve-rds-snapshot/version'

Gem::Specification.new do |spec|
  spec.name          = "preserve-rds-snapshot"
  spec.version       = PreserveRdsSnapshot::VERSION
  spec.authors       = ["ISOBE Kazuhiko"]
  spec.email         = ["muramasa64@gmail.com"]

  spec.summary       = %q{Preserve RDS Snapshot}
  spec.description   = %q{Amazon RDS create a snapshot automatically. Snapshot that is created automatically, will be lost when the instance is terminated. This script preserve db snapshots by copy snapshots.}
  spec.homepage      = "https://guthub.com/muramasa64/preserve-rds-snapshot"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    #spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "thor-aws"
end
