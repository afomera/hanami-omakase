# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/omakase/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami-omakase"
  spec.authors       = ["Andrea Fomera"]
  spec.email         = ["afomera@hey.com"]
  spec.license       = "MIT"
  spec.version       = Hanami::Omakase::VERSION.dup

  spec.summary       = "Hanami Omakase: Defaults picked for you"
  spec.description   = spec.summary
  spec.homepage      = "https://afomera.dev"
  spec.files         = Dir["LICENSE", "README.md", "hanami-omakase.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = ["README.md", "LICENSE"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/afomera/hanami-omakase/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/afomera/hanami-omakase"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/afomera/hanami-omakase/issues"

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_runtime_dependency "hanami", ">= 2.2"
  spec.add_runtime_dependency "hanami-utils", ">= 2.2"
  spec.add_runtime_dependency "hanami-controller", ">= 2.2"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard"
end
