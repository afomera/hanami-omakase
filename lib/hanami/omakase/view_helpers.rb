# frozen_string_literal: true

module Hanami
  module Omakase
    module ViewHelpers
      def url_for(name, **options)
        routes.url(name, **options)
      end

      def path_for(name, **options)
        routes.path(name, **options)
      end
    end
  end
end

Hanami::Extensions::View::StandardHelpers.include(Hanami::Omakase::ViewHelpers)
