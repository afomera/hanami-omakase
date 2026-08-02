# frozen_string_literal: true

require "hanami"

module Hanami
  module Omakase
    module ViewHelpers
      def url_for(name, **options)
        routes.url(name, **options)
      end

      def path_for(name, **options)
        routes.path(name, **options)
      end

      def button_to(name, url = nil, method: :post, **options)
        action = url || url_for(name, **options)
        hidden = method.to_sym != :post ? %{<input type="hidden" name="_method" value="#{method}" />} : ""
        attrs = options.map { |k, v| %{"#{k}="#{v}" } }.join(" ")
        %{<form method="post" action="#{action}" class="button_to">#{hidden}<input type="submit" value="#{name}" #{attrs} /></form>}
      end
    end
  end
end

Hanami::Extensions::View::StandardHelpers.include(Hanami::Omakase::ViewHelpers)
