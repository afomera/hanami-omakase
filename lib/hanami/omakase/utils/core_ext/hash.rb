# frozen_string_literal: true

class Hash
  alias_method :blank?, :empty?

  def present?
    !empty?
  end
end
