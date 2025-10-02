# frozen_string_literal: true

require "zeitwerk"

require "hanami/omakase/utils"
require "hanami/omakase/action"

module Hanami
  module Omakase
    # @api private
    def self.loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path "..", __dir__
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/hanami/omakase.rb")
        loader.tag = "hanami-omakase"
        loader.push_dir root
      end
    end
    loader.setup
  end
end
