# frozen_string_literal: true

require "hanami/routes"

module Hanami
  module Omakase
    module Routing
      # Resource-style resource routing for Hanami
      #
      # Provides `resource` and `resources` methods to generate RESTful routes
      # for provided resource names, following common conventions.
      #
      # Usage:
      #   class Routes < Hanami::Routes
      #     include Hanami::Omakase::Routing
      #
      #     resources :users
      #     resource :profile
      #   end
      #
      # `resources :users` generates:
      #   GET    /users          users.index
      #   GET    /users/new      users.new
      #   POST   /users          users.create
      #   GET    /users/:id      users.show
      #   GET    /users/:id/edit users.edit
      #   PATCH  /users/:id      users.update
      #   PUT    /users/:id      users.update
      #   DELETE /users/:id      users.destroy
      #
      # `resource :profile` generates (singular, no index):
      #   GET    /profile/new    profile.new
      #   POST   /profile        profile.create
      #   GET    /profile        profile.show
      #   GET    /profile/edit   profile.edit
      #   PATCH  /profile        profile.update
      #   PUT    /profile        profile.update
      #   DELETE /profile        profile.destroy

      # Generate RESTful routes for a plural resource
      # @param name [Symbol] The resource name (plural)
      # @param options [Hash] Options for customizing the routes
      # @option options [Array<Symbol>] :only Limit to specific actions
      # @option options [Array<Symbol>] :except Exclude specific actions
      # @option options [String] :controller Override the controller name
      # @option options [String] :path Override the URL path
      # @option options [String, Symbol] :as Override the route name prefix
      def resources(name, **options, &block)
        resource_builder = ResourceBuilder.new(
          router: self,
          name: name,
          type: :plural,
          options: options
        )

        resource_builder.build_routes

        if block_given?
          nested_context = NestedResourceContext.new(self, resource_builder.path)
          nested_context.instance_eval(&block)
        end
      end

      # Generate RESTful routes for a singular resource
      # @param name [Symbol] The resource name (singular)
      # @param options [Hash] Options for customizing the routes
      # @option options [Array<Symbol>] :only Limit to specific actions
      # @option options [Array<Symbol>] :except Exclude specific actions
      # @option options [String] :controller Override the controller name
      # @option options [String] :path Override the URL path
      # @option options [String, Symbol] :as Override the route name
      def resource(name, **options, &block)
        resource_builder = ResourceBuilder.new(
          router: self,
          name: name,
          type: :singular,
          options: options
        )

        resource_builder.build_routes

        if block_given?
          nested_context = NestedResourceContext.new(self, resource_builder.path)
          nested_context.instance_eval(&block)
        end
      end

      # Builds RESTful routes for a resource
      class ResourceBuilder
        attr_reader :router, :name, :type, :options, :controller, :path, :route_name

        def initialize(router:, name:, type:, options:)
          @router = router
          @name = name
          @type = type
          @options = options
          @controller = options[:controller] || name.to_s
          @path = options[:path] || name.to_s
          @route_name = determine_route_name
        end

        def build_routes
          allowed_actions.each do |action|
            route_config = ROUTE_CONFIGURATIONS[action]
            next unless route_config

            build_route(action, route_config)
          end
        end

        private

        ROUTE_CONFIGURATIONS = {
          index: {method: :get, path_suffix: "", name_suffix: ""},
          new: {method: :get, path_suffix: "/new", name_suffix: "new_"},
          create: {method: :post, path_suffix: "", name_suffix: ""},
          show: {method: :get, path_suffix: "/:id", name_suffix: ""},
          edit: {method: :get, path_suffix: "/:id/edit", name_suffix: "edit_"},
          update: [
            {method: :patch, path_suffix: "/:id", name_suffix: ""},
            {method: :put, path_suffix: "/:id", name_suffix: ""}
          ],
          destroy: {method: :delete, path_suffix: "/:id", name_suffix: ""}
        }.freeze

        def determine_route_name
          if options[:as]
            options[:as].to_s
          elsif type == :plural
            Inflector.singularize(name.to_s)
          else
            name.to_s
          end
        end

        def allowed_actions
          default_actions = type == :plural ? PLURAL_ACTIONS : SINGULAR_ACTIONS
          ActionFilter.filter(default_actions, options)
        end

        PLURAL_ACTIONS = %i[index new create show edit update destroy].freeze
        SINGULAR_ACTIONS = %i[new create show edit update destroy].freeze

        def build_route(action, config)
          configs = config.is_a?(Array) ? config : [config]

          configs.each do |route_config|
            route_path = build_route_path(route_config[:path_suffix])
            route_name = build_route_name(action, route_config[:name_suffix])
            controller_action = "#{controller}.#{action}"

            router.public_send(
              route_config[:method],
              route_path,
              to: controller_action,
              as: route_name
            )
          end
        end

        def build_route_path(suffix)
          base_path = "/#{path}"
          suffix = resolve_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def build_route_name(action, prefix)
          base_name = action == :index ? Inflector.pluralize(route_name) : route_name
          prefix.empty? ? base_name : "#{prefix}#{base_name}"
        end

        def resolve_suffix(suffix)
          return "" if suffix.nil? || suffix.empty?
          return "" if suffix == "/:id" && type == :singular

          suffix
        end
      end

      # Filters actions based on :only and :except options
      class ActionFilter
        def self.filter(default_actions, options)
          if options[:only]
            Array(options[:only]) & default_actions
          elsif options[:except]
            default_actions - Array(options[:except])
          else
            default_actions
          end
        end
      end

      # Simple inflection utilities
      module Inflector
        def self.singularize(word)
          word.chomp("s")
        end

        def self.pluralize(word)
          word.end_with?("s") ? word : "#{word}s"
        end
      end

      # Context for handling nested resources
      class NestedResourceContext
        def initialize(router, parent_path)
          @router = router
          @parent_path = parent_path
        end

        def resources(name, **options)
          build_nested_resource(name, :plural, options)
        end

        def resource(name, **options)
          build_nested_resource(name, :singular, options)
        end

        private

        def build_nested_resource(name, type, options)
          nested_builder = NestedResourceBuilder.new(
            router: @router,
            parent_path: @parent_path,
            name: name,
            type: type,
            options: options
          )

          nested_builder.build_routes
        end
      end

      # Builds nested resource routes
      class NestedResourceBuilder < ResourceBuilder
        attr_reader :parent_path, :parent_name

        def initialize(router:, parent_path:, name:, type:, options:)
          super(router: router, name: name, type: type, options: options)
          @parent_path = parent_path
          @parent_name = Inflector.singularize(parent_path.to_s)
        end

        private

        def build_route_path(suffix)
          base_path = "/#{parent_path}/:#{parent_name}_id/#{path}"
          suffix = resolve_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def build_route_name(action, prefix)
          base_name = action == :index ? Inflector.pluralize(route_name) : route_name
          nested_name = "#{parent_name}_#{base_name}"
          prefix.empty? ? nested_name : "#{prefix}#{nested_name}"
        end
      end
    end
  end
end

# Auto-include the routing module in Hanami::Routes if it's available
if defined?(Hanami::Router)
  Hanami::Router.prepend(Hanami::Omakase::Routing)
end
