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
        controller = options[:controller] || name.to_s
        path = options[:path] || name.to_s
        route_name = options[:as] || singularize(name.to_s)
        actions = determine_actions(%i[index new create show edit update destroy], options)

        # Index route
        if actions.include?(:index)
          get "/#{path}", to: "#{controller}.index", as: pluralize(route_name)
        end

        # New route
        if actions.include?(:new)
          get "/#{path}/new", to: "#{controller}.new", as: "new_#{route_name}"
        end

        # Create route
        if actions.include?(:create)
          post "/#{path}", to: "#{controller}.create", as: pluralize(route_name)
        end

        # Show route
        if actions.include?(:show)
          get "/#{path}/:id", to: "#{controller}.show", as: route_name
        end

        # Edit route
        if actions.include?(:edit)
          get "/#{path}/:id/edit", to: "#{controller}.edit", as: "edit_#{route_name}"
        end

        # Update routes
        if actions.include?(:update)
          patch "/#{path}/:id", to: "#{controller}.update", as: route_name
          put "/#{path}/:id", to: "#{controller}.update", as: route_name
        end

        # Destroy route
        if actions.include?(:destroy)
          delete "/#{path}/:id", to: "#{controller}.destroy", as: route_name
        end

        # Handle nested resources if block given
        if block_given?
          nested_context = NestedResourceContext.new(self, path)
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
        controller = options[:controller] || name.to_s
        path = options[:path] || name.to_s
        route_name = options[:as] || name.to_s
        actions = determine_actions(%i[new create show edit update destroy], options)

        # New route
        if actions.include?(:new)
          get "/#{path}/new", to: "#{controller}.new", as: "new_#{route_name}"
        end

        # Create route
        if actions.include?(:create)
          post "/#{path}", to: "#{controller}.create", as: route_name
        end

        # Show route
        if actions.include?(:show)
          get "/#{path}", to: "#{controller}.show", as: route_name
        end

        # Edit route
        if actions.include?(:edit)
          get "/#{path}/edit", to: "#{controller}.edit", as: "edit_#{route_name}"
        end

        # Update routes
        if actions.include?(:update)
          patch "/#{path}", to: "#{controller}.update", as: route_name
          put "/#{path}", to: "#{controller}.update", as: route_name
        end

        # Destroy route
        if actions.include?(:destroy)
          delete "/#{path}", to: "#{controller}.destroy", as: route_name
        end

        # Handle nested resources if block given
        if block_given?
          nested_context = NestedResourceContext.new(self, path)
          nested_context.instance_eval(&block)
        end
      end

      private

      def determine_actions(default_actions, options)
        if options[:only]
          Array(options[:only]) & default_actions
        elsif options[:except]
          default_actions - Array(options[:except])
        else
          default_actions
        end
      end

      # Simple singularization - removes 's' from end
      # For more complex cases, could integrate with inflection library
      def singularize(word)
        word.chomp("s")
      end

      # Simple pluralization - adds 's' to end
      # For more complex cases, could integrate with inflection library
      def pluralize(word)
        word.end_with?("s") ? word : "#{word}s"
      end

      # Context for handling nested resources
      class NestedResourceContext
        def initialize(router, parent_path)
          @router = router
          @parent_path = parent_path
        end

        def resources(name, **options)
          controller = options[:controller] || name.to_s
          path = options[:path] || name.to_s
          route_name = options[:as] || @router.send(:singularize, name.to_s)
          parent_name = singular_parent_name
          actions = @router.send(:determine_actions, %i[index new create show edit update destroy], options)

          # Nested routes with parent ID
          if actions.include?(:index)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.index",
                                                                       as: "#{parent_name}_#{@router.send(:pluralize, route_name)}"
          end

          if actions.include?(:new)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}/new", to: "#{controller}.new",
                                                                           as: "new_#{parent_name}_#{route_name}"
          end

          if actions.include?(:create)
            @router.post "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.create",
                                                                        as: "#{parent_name}_#{@router.send(:pluralize, route_name)}"
          end

          if actions.include?(:show)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}/:id", to: "#{controller}.show",
                                                                           as: "#{parent_name}_#{route_name}"
          end

          if actions.include?(:edit)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}/:id/edit", to: "#{controller}.edit",
                                                                                as: "edit_#{parent_name}_#{route_name}"
          end

          if actions.include?(:update)
            @router.patch "/#{@parent_path}/:#{parent_name}_id/#{path}/:id", to: "#{controller}.update",
                                                                             as: "#{parent_name}_#{route_name}"
            @router.put "/#{@parent_path}/:#{parent_name}_id/#{path}/:id", to: "#{controller}.update",
                                                                           as: "#{parent_name}_#{route_name}"
          end

          if actions.include?(:destroy)
            @router.delete "/#{@parent_path}/:#{parent_name}_id/#{path}/:id", to: "#{controller}.destroy",
                                                                              as: "#{parent_name}_#{route_name}"
          end
        end

        def resource(name, **options)
          controller = options[:controller] || name.to_s
          path = options[:path] || name.to_s
          route_name = options[:as] || name.to_s
          parent_name = singular_parent_name
          actions = @router.send(:determine_actions, %i[new create show edit update destroy], options)

          # Nested singular resource routes
          if actions.include?(:new)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}/new", to: "#{controller}.new",
                                                                           as: "new_#{parent_name}_#{route_name}"
          end

          if actions.include?(:create)
            @router.post "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.create",
                                                                        as: "#{parent_name}_#{route_name}"
          end

          if actions.include?(:show)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.show",
                                                                       as: "#{parent_name}_#{route_name}"
          end

          if actions.include?(:edit)
            @router.get "/#{@parent_path}/:#{parent_name}_id/#{path}/edit", to: "#{controller}.edit",
                                                                            as: "edit_#{parent_name}_#{route_name}"
          end

          if actions.include?(:update)
            @router.patch "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.update",
                                                                         as: "#{parent_name}_#{route_name}"
            @router.put "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.update",
                                                                       as: "#{parent_name}_#{route_name}"
          end

          if actions.include?(:destroy)
            @router.delete "/#{@parent_path}/:#{parent_name}_id/#{path}", to: "#{controller}.destroy",
                                                                          as: "#{parent_name}_#{route_name}"
          end
        end

        private

        def singular_parent_name
          # Simple singularization - remove 's' from end
          # For more complex cases, could integrate with inflection library
          @parent_path.to_s.chomp("s")
        end
      end
    end
  end
end

# Auto-include the routing module in Hanami::Routes if it's available
if defined?(Hanami::Routes)
  Hanami::Router.prepend(Hanami::Omakase::Routing)
end
