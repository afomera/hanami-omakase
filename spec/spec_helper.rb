# frozen_string_literal: true

require "pathname"
SPEC_ROOT = Pathname(__dir__).realpath.freeze

Bundler.require :tools

require "hanami/omakase"

require_relative "support/rspec"
Dir.glob(SPEC_ROOT / "support" / "**" / "*.rb").each { |f| require f }
