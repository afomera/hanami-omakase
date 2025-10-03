# frozen_string_literal: true

module Hanami
  module Omakase
    module Errors
      class Middleware
        def initialize(app, options = {})
          @app = app
          @show_exceptions = options.fetch(:show_exceptions, true)
          @consider_all_requests_local = options.fetch(:consider_all_requests_local, development?)
        end

        def call(env)
          @app.call(env)
        rescue StandardError => exception
          if show_exceptions_for_request?(env)
            render_error_page(exception, env)
          else
            render_simple_error_response(exception, env)
          end
        end

        private

        attr_reader :show_exceptions, :consider_all_requests_local

        def show_exceptions_for_request?(env)
          # return true # HACK: to always show exceptions
          return false unless @show_exceptions
          return true if @consider_all_requests_local

          # Check if request is from localhost
          request = Rack::Request.new(env)
          local_request?(request)
        end

        def local_request?(request)
          return true if request.ip == "127.0.0.1"
          return true if request.ip == "::1"
          return true if request.ip == "0.0.0.0"

          # Check for private network ranges
          return true if request.ip&.start_with?("192.168.")
          return true if request.ip&.start_with?("10.")
          return true if request.ip&.match?(/^172\.(1[6-9]|2[0-9]|3[01])\./)

          false
        end

        def render_error_page(error, env)
          request = Rack::Request.new(env)
          renderer = ErrorPageRenderer.new(error, request)
          html_content = renderer.render

          [
            500,
            {
              "Content-Type" => "text/html; charset=utf-8",
              "Content-Length" => html_content.bytesize.to_s
            },
            [html_content]
          ]
        end

        def render_simple_error_response(error, env)
          # Simple error response for production or non-local requests
          message = production? ? "Internal Server Error" : error.message

          [
            500,
            {
              "Content-Type" => "text/plain; charset=utf-8",
              "Content-Length" => message.bytesize.to_s
            },
            [message]
          ]
        end

        def development?
          ENV.fetch("HANAMI_ENV", "development") == "development"
        end

        def production?
          ENV.fetch("HANAMI_ENV", "development") == "production"
        end
      end
    end
  end
end
