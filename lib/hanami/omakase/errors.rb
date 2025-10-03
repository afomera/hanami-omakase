# frozen_string_literal: true

require "hanami/omakase/errors/error_patches"

module Hanami
  module Omakase
    module Errors
      # Helper method to configure the actionable errors middleware in a Hanami app
      #
      # @example Basic usage in config/app.rb
      #   require "hanami/omakase"
      #
      #   module MyApp
      #     class App < Hanami::App
      #       config.middleware.use(*Hanami::Omakase::Errors.middleware)
      #     end
      #   end
      #
      # @example With custom options
      #   config.middleware.use(*Hanami::Omakase::Errors.middleware(
      #     show_exceptions: true,
      #     consider_all_requests_local: false
      #   ))
      #
      # @param options [Hash] Configuration options for the middleware
      # @option options [Boolean] :show_exceptions (true) Whether to show detailed error pages
      # @option options [Boolean] :consider_all_requests_local (development?) Whether to treat all requests as local
      # @return [Array] Array containing the middleware class and options
      def self.middleware(options = {})
        [Hanami::Omakase::Errors::Middleware, options]
      end

      # Convenience method to check if we're in development environment
      def self.development?
        ENV.fetch("HANAMI_ENV", "development") == "development"
      end
    end
  end
end
