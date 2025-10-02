# frozen_string_literal: true

require "hanami/action"

module Hanami
  module Omakase
    # Exception raised when a requested format is not handled by the action
    class UnknownFormatError < StandardError
      def initialize(format, defined_formats)
        super("Format '#{format}' is not supported. Defined formats: #{defined_formats.join(', ')}")
      end
    end

    module Action
      # Spec out support for Hanami::Action in the def handle(request, response) method
      # to be able to respond to multiple formats easily.
      #
      # Inspired by the `respond_to` method in Rails controllers.
      #
      # Supported formats: :html, :json, :xml, :md
      #
      # Raises Hanami::Omakase::UnknownFormatError if the requested format is not handled.
      #
      # Usage:
      #   class MyAction
      #     include Hanami::Action
      #
      #     def handle(request, response)
      #       respond_with do |format|
      #         format.html { response.render(view, per_page: 10, page: params[:page]) }
      #         format.json { response.render(view, per_page: 20) } # format: :json added automatically
      #         format.xml  { response.render(view) } # format: :xml added automatically
      #       end
      #     end
      #   end
      #
      # For non-HTML formats, both format and layout are automatically handled:
      # - format: :json (or :xml) is automatically added
      # - layout: nil is automatically set to disable layouts
      # Your other parameters (per_page, page, etc.) are preserved and work normally.
      # You can override either by explicitly passing format: :something or layout: MyLayout.
      def respond_with(&block)
        req, res = extract_request_response(block.binding)
        responder = FormatResponder.new(req, res, self)
        yield responder
        responder.validate_format_handled!
      end

      private

      def extract_request_response(binding)
        local_vars = binding.local_variables

        req = local_vars.length >= 1 ? binding.local_variable_get(local_vars[0]) : nil
        res = local_vars.length >= 2 ? binding.local_variable_get(local_vars[1]) : nil

        # Fallback to instance methods if available
        req ||= (respond_to?(:request, true) ? request : nil)
        res ||= (respond_to?(:response, true) ? response : nil)

        [req, res]
      end

      class FormatResponder
        SUPPORTED_FORMATS = %w[html json xml md].freeze

        CONTENT_TYPES = {
          html: "text/html",
          json: "application/json",
          xml: "application/xml",
          md: "text/markdown"
        }.freeze

        def initialize(request, response, action = nil)
          @request = request
          @response = response
          @action = action
          @content_type = nil
          @defined_formats = []
          @current_format = nil
        end

        SUPPORTED_FORMATS.each do |format|
          define_method(format) do |&block|
            @defined_formats << format.to_sym
            respond_to_format(format.to_sym, &block)
          end
        end

        def validate_format_handled!
          requested_format = content_type
          return if @defined_formats.include?(requested_format)

          raise UnknownFormatError.new(requested_format, @defined_formats)
        end

        private

        def respond_to_format(format, &block)
          return unless content_type == format && block_given?

          _set_response_format(format)
          @current_format = format

          # Enhance the response's render method if available
          _enhance_response_render_method(format) if @response&.respond_to?(:render)

          block.call
        ensure
          # Restore original render method after block execution
          _restore_response_render_method if @response && @original_render_method
        end

        def _set_response_format(format)
          return unless @response

          @response.format = format

          content_type_header = CONTENT_TYPES[format]
          @response.headers["Content-Type"] = content_type_header if content_type_header
        end

        def _enhance_response_render_method(format)
          return unless @response.respond_to?(:render)

          # Store original render method in local variable for closure
          original_render_method = @response.method(:render)
          @original_render_method = original_render_method # Keep for cleanup

          # Define enhanced render method that automatically includes format and layout handling
          @response.define_singleton_method(:render) do |*args, **kwargs|
            # If format is not explicitly provided and we're not rendering HTML, add it
            if format != :html && !kwargs.key?(:format)
              kwargs[:format] = format
            end

            # For non-HTML formats, disable layout unless explicitly specified
            if format != :html && !kwargs.key?(:layout)
              kwargs[:layout] = nil
            end

            original_render_method.call(*args, **kwargs)
          end
        end

        def _restore_response_render_method
          return unless @response && @original_render_method

          # Restore the original render method
          @response.define_singleton_method(:render, @original_render_method)
          @original_render_method = nil
        end

        def content_type
          @content_type ||= determine_content_type
        end

        def determine_content_type
          return :html unless @request

          # Check format parameter first (most explicit)
          format_from_params || format_from_path_extension || format_from_accept_header
        end

        def format_from_params
          return unless @request.respond_to?(:params) && @request.params

          format_param = @request.params[:format]
          return unless format_param && SUPPORTED_FORMATS.include?(format_param.to_s)

          format_param.to_s.to_sym
        end

        def format_from_path_extension
          path_info = @request.get_header("PATH_INFO")
          return unless path_info&.include?(".")

          ext = File.extname(path_info).delete_prefix(".")
          return unless SUPPORTED_FORMATS.include?(ext)

          ext.to_sym
        end

        def format_from_accept_header
          accept_header = @request.get_header("HTTP_ACCEPT")
          return unless accept_header

          accept_types = parse_accept_header(accept_header)
          determine_format_from_accept_types(accept_types)
        end

        def parse_accept_header(accept_header)
          accept_header.split(",").map do |type|
            parts = type.strip.split(";")
            media_type = parts[0].strip
            quality = extract_quality(parts)

            {type: media_type, quality: quality}
          end.sort_by { |t| -t[:quality] }
        end

        def extract_quality(parts)
          quality_part = parts.find { |p| p.strip.start_with?("q=") }
          return 1.0 unless quality_part

          quality_part.split("=")[1].to_f
        rescue StandardError
          1.0
        end

        def determine_format_from_accept_types(accept_types)
          detect_json_format(accept_types) ||
            detect_html_xml_format(accept_types)
        end

        def detect_json_format(accept_types)
          json_type = find_accept_type(accept_types, "application/json")
          :json if json_type && acceptable_quality?(json_type)
        end

        def detect_html_xml_format(accept_types)
          html_type = find_accept_type(accept_types, "text/html")
          xml_type = find_xml_accept_type(accept_types)

          return resolve_html_xml_conflict(html_type, xml_type) if html_type && xml_type
          return :html if html_type

          :xml if xml_type && acceptable_quality?(xml_type)
        end

        def find_accept_type(accept_types, media_type)
          accept_types.find { |t| t[:type] == media_type }
        end

        def find_xml_accept_type(accept_types)
          accept_types.find { |t| t[:type] == "application/xml" || t[:type] == "text/xml" }
        end

        def acceptable_quality?(type)
          type[:quality] > 0.5
        end

        def resolve_html_xml_conflict(html_type, xml_type)
          xml_type[:quality] > html_type[:quality] + 0.1 ? :xml : :html
        end
      end
    end
  end
end

# Automatically include Omakase::Action functionality in all Hanami::Action classes
if defined?(Hanami::Action)
  Hanami::Action.include(Hanami::Omakase::Action) # :nodoc:
end
