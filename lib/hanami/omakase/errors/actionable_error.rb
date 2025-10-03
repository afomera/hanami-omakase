# frozen_string_literal: true

module Hanami
  module Omakase
    module Errors
      module ActionableError
        # Action class to define actionable behaviors
        class Action
          attr_reader :name, :description, :handler

          def initialize(name, description, &handler)
            @name = name.to_s
            @description = description
            @handler = handler
          end

          def call(*args)
            handler.call(*args) if handler
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.class_eval do
            @actions = {}
          end
        end

        module ClassMethods
          # Register an action for this error class
          def action(name, description, &block)
            @actions ||= {}
            @actions[name.to_s] = Action.new(name, description, &block)
          end

          # Get all registered actions
          def actions
            @actions ||= {}
          end

          # Get a specific action by name
          def action_for(name)
            actions[name.to_s]
          end

          # Check if an action exists
          def action?(name)
            actions.key?(name.to_s)
          end
        end

        # Instance methods for error objects
        def actions
          self.class.actions
        end

        def action_for(name)
          self.class.action_for(name)
        end

        def action?(name)
          self.class.action?(name)
        end

        def execute_action(name, *args)
          action = action_for(name)
          return false unless action

          action.call(self, *args)
          true
        end

        def actionable?
          !actions.empty?
        end

        def action_names
          actions.keys
        end

        def action_descriptions
          actions.transform_values(&:description)
        end
      end
    end
  end
end
