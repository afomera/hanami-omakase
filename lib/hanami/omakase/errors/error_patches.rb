# frozen_string_literal: true

module Hanami
  module Omakase
    module Errors
      module ErrorPatches
      end
    end
  end
end

# Patch Hanami::Router errors to include ActionableError concern
if defined?(::Hanami::Router)
  module Hanami
    class Router
      class MissingActionError < Hanami::Router::Error
        include Hanami::Omakase::Errors::ActionableError
      end

      class MissingEndpointError < Hanami::Router::Error
        include Hanami::Omakase::Errors::ActionableError

        # Add some default actions for missing endpoint errors
        action :create_route, "Create a route for this endpoint" do |error|
          # This could be implemented to suggest route creation
          puts "Suggested route: #{error.message}"
        end

        action :check_routes, "Check existing routes" do |error|
          # This could list existing routes
          puts "Check your routes configuration"
        end
      end
    end
  end
end
